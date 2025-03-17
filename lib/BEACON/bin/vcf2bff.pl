#!/usr/bin/env perl
#
#   Script to parse a VCF having SnepEff/SnpSift ANN fields
#   The output can be:
#       a) genomicVariantsVcf.json.gz [bff]
#       b) Standard JSON [json] (STDOUT)
#       c) Perl hash data structure [hash] (STDOUT)
#
#   Last Modified: Mar/17/2025
#
#   Version taken from $beacon
#
#   Copyright (C) 2021-2022 Manuel Rueda - CRG
#   Copyright (C) 2023-2025 Manuel Rueda - CNAG (manuel.rueda@cnag.eu)
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, see <https://www.gnu.org/licenses/>.
#
#   If this program helps you in your research, please cite.

use strict;
use warnings;
use autodie;
use feature qw(say);
use Getopt::Long;
use Pod::Usage;
use Sys::Hostname;
use Cwd qw(cwd abs_path);
use Data::Dumper;
use JSON::XS;
use FindBin               qw($Bin);
use YAML::XS              qw(LoadFile);
use File::Spec::Functions qw(catfile);
use lib "$Bin/lib";
use BFF;
use BFF::Data qw(%chr_name_conv %vcf_data_loc);

# -----------------------
#  Named Constants for Output Formats
# -----------------------
use constant {
    FORMAT_BFF  => 'bff',
    FORMAT_JSON => 'json',
    FORMAT_HASH => 'hash',
};

$Data::Dumper::Sortkeys = 1;

#$Data::Dumper::Sortkeys = sub {
#    no warnings 'numeric';
#    [ sort { $a <=> $b } keys %{ $_[0] } ];
#};

### Main ###
vcf2bff();
############
exit;

###############################################################################
# Main vcf2bff Subroutine
###############################################################################
sub vcf2bff {

    my $version  = '2.0.8'; 
    my $DEFAULT  = '.';
    my $exe_path = abs_path($0);
    my $cwd      = cwd;
    my $user     = $ENV{LOGNAME} || $ENV{USER} || getpwuid($<);

    # Parse CLI arguments first
    my $cli = parse_cli_args($version);

    # You could set defaults if not provided:
    my $format = $cli->{format} // FORMAT_BFF;

    # Load external config.yaml
    my $config_file = catfile($Bin, 'config.yaml');
    my $config      = LoadFile($config_file)
      or die "[vcf2bff] Could not load $config_file";

    # We expect $config->{annotatedWith}
    my $annotated_with = $config->{annotatedWith}
      or die "[vcf2bff] Missing 'annotatedWith' key in $config_file";

    chomp(my $threadshost = qx{/usr/bin/nproc} // 1);
    $threadshost = 0 + $threadshost;  # Coerce to number
    my $fileout   = 'genomicVariationsVcf.json.gz';
    my $skip_structural_variation = 1;

    # Debug / verbose info
    my $prompt = 'Info:';
    my $spacer = '*' x 28;
    my $arrow  = '=>';
    my $author = 'Manuel Rueda, PhD';

    # Prepare a param hash
    my %param = (
        user        => $user,
        hostname    => hostname,
        cwd         => $cwd,
        projectDir  => $cli->{project_dir},
        version     => $version,
        threadshost => $threadshost,
        filein      => $cli->{filein},
        fileout     => $fileout,
    );

    # Output format subroutines
    my %serialize = (
        FORMAT_BFF()  => 'data2bff',
        FORMAT_JSON() => 'data2json',
        FORMAT_HASH() => 'data2hash',
    );
    my $serialize = $serialize{$format};

    # Possibly flush STDOUT early if in debug/verbose mode
    my $debug   = $cli->{debug}   // 0;
    my $verbose = $cli->{verbose} // 0;
    $| = 1 if ($debug || $verbose);

    # Print argument info if verbose
    if ($debug || $verbose) {
        say "$prompt\n$prompt vcf2bff $version\n$prompt vcf2bff exe $exe_path\n$prompt Author: $author\n$prompt";
        say "$prompt ARGUMENTS USED:";
        say "$prompt --i $cli->{filein}";
        say "$prompt --genome $cli->{genome}";
        say "$prompt --format $format";
        say "$prompt --dataset-id $cli->{dataset_id}";
        say "$prompt --project-dir $cli->{project_dir}";
        say "$prompt --debug $debug"    if $debug;
        say "$prompt --verbose"         if $verbose;
        say "$prompt\n$prompt VCF2BFF PARAMETERS:";
        my $param_key = '';
        $~ = "PARAMS";

        foreach $param_key (sort keys %param) {
            write;
        }

        format PARAMS =
@|||||@<<<<<<<<<<<<<<<< @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$prompt, $param_key, $arrow, $param{$param_key}
.

        say "$prompt\n$prompt $spacer\n$prompt STARTING VCF2BFF";
    }

    #############################
    # NOTE ABOUT ANNOTATIONS    #
    #############################
    # The annotations come in 4 flavours:
    #  1 - SnpEff
    #  2 - dbNSFP
    #  3 - ClinVar
    #  4 - COSMIC
    # Some fields overlap between them.

    my @keys2load = grep { $_ ne 'SAMPLES' } keys %vcf_data_loc;

    ############################################
    #   PARSE THE VCF FILE
    ############################################
    open my $fh_in,  '<:gzip', $cli->{filein};
    open my $fh_out, '>:gzip', $fileout;
    say $fh_out "[";

    my $count = 0;
    my @snpeff_fields;
    my %ann_field_data_loc;
    my %sample_id;

    while (defined(my $line = <$fh_in>)) {
        if ($line =~ /^#/) {
            @snpeff_fields = parse_header_snpeff($line)
              if $line =~ /^##INFO=<ID=ANN,Number/;

            %ann_field_data_loc =
              map { $_, $snpeff_fields[$_] } (0 .. $#snpeff_fields)
              if @snpeff_fields;

            %sample_id = parse_header_samples($line, $vcf_data_loc{SAMPLES})
              if $line =~ /^#CHR/;
            next;
        }

        $count++;
        chomp $line;
        my @vcf_fields = split /\t/, $line;
        my %vcf_fields_short;

        for my $key (@keys2load) {
            $vcf_fields_short{$key} = $vcf_fields[$vcf_data_loc{$key}];
        }

        my $uid = 'chr'
          . $vcf_fields_short{CHROM} . '_'
          . $vcf_fields_short{POS}   . '_'
          . $vcf_fields_short{REF}   . '_'
          . $vcf_fields_short{ALT};

        # Skip structural variants if requested
        if ($skip_structural_variation && $vcf_fields_short{ALT} =~ m/^</) {
            next;
        }

        # SnpEff might annotate multiple dbSNP IDs with semicolons
        $vcf_fields_short{ID} =~ tr/;/,/;

        ##################
        # VCF-INFO field #
        ##################
        my %info_hash = parse_info_field($vcf_fields_short{INFO}, $uid);

        unless (exists $info_hash{VT} && $info_hash{VT} !~ m/,/) {
            $info_hash{VT} = guess_variant_type(
                $vcf_fields_short{REF},
                $vcf_fields_short{ALT}
            );
        }

        $info_hash{MULTI_ALLELIC} = ($line =~ m/;MULTI_ALLELIC;/) ? 'yes' : 'no';

        ######################
        # VCF-INFO-ANN field #
        ######################
        if (exists $info_hash{ANN}) {
            $info_hash{ANN} = parse_ann_field(
                $info_hash{ANN},
                \%ann_field_data_loc,
                $#snpeff_fields,
                $uid,
                $vcf_fields_short{ALT},
                $DEFAULT
            );
        }
        else {
            $info_hash{ANN} = undef;
        }

        unless (defined $info_hash{ANN}) {
            warn "[vcf2bff] WARNING: Skipping <$uid> - no INFO=<ID=ANN>\n";
            next;
        }

        ######################
        #   GENOTYPES
        ######################
        my @genotypes = @vcf_fields[$vcf_data_loc{SAMPLES} .. $#vcf_fields];
        my ($pruned_genotypes, $n_calls) = prune_genotypes({
            gt        => \@genotypes,
            sample_id => \%sample_id,
            format    => $vcf_fields_short{FORMAT},
        });

        my %crg_hash;
        # Fill out %crg_hash{INFO}{vcf2bff} with param data
        for my $k (keys %param) {
            $crg_hash{INFO}{vcf2bff}{$k} = $param{$k};
        }
        $crg_hash{INFO}{genome}    = $cli->{genome};
        $crg_hash{INFO}{datasetId} = $cli->{dataset_id};

        # From config.yaml
        $crg_hash{ANNOTATED_WITH} = $annotated_with;

        my $n_samples = scalar(keys %sample_id);
        $crg_hash{SAMPLES_ALT}     = $pruned_genotypes;
        $crg_hash{N_SAMPLES_ALT}   = $n_calls;
        $crg_hash{N_SAMPLES}       = $n_samples;
        $crg_hash{CALLS_FREQUENCY} = sprintf "%10.8f", ($n_calls / $n_samples);
        $crg_hash{CUSTOM_VAR_ID}   = $count;
        $crg_hash{REFSEQ}          = $chr_name_conv{$vcf_fields_short{CHROM}};
        $crg_hash{POS}    = $vcf_fields_short{POS};
        $crg_hash{ENDPOS} = $crg_hash{POS};

        # 0-based
        $crg_hash{POS_ZERO_BASED}    = $crg_hash{POS} - 1;
        $crg_hash{ENDPOS_ZERO_BASED} = $crg_hash{ENDPOS};

        $info_hash{CRG} = \%crg_hash;

        # Build final data structure
        my $hash_out = {};
        foreach my $key (@keys2load) {
            $hash_out->{$uid}{$key} = ($key eq 'INFO') ? \%info_hash : $vcf_fields_short{$key};
        }

        # Serialize
        my $bff = BFF->new($hash_out);
        print $fh_out $bff->$serialize($uid, $verbose);
        print $fh_out ",\n" unless eof;

        if (($debug || $verbose) && $count % 10_000 == 0) {
            say "$prompt Variants processed = $count";
        }
    }

    say $fh_out "\n]";
    close $fh_in;
    close $fh_out;

    say "$prompt $spacer\n$prompt VCF2BFF FINISHED OK"
      if ($debug || $verbose);

    return 1;
}

###############################################################################
# Subroutine to Parse CLI Arguments & Do Usage Checks
###############################################################################
sub parse_cli_args {
    my $version = shift;

    my %opts;
    # Set some defaults if you want (e.g. format => FORMAT_BFF).
    # We'll let vcf2bff() do that if needed, but you can do it here, too.
    GetOptions(
        'input|i=s'       => \$opts{filein},         # string
        'format|f=s'      => \$opts{format},         # string
        'dataset-id|d=s'  => \$opts{dataset_id},     # string
        'project-dir|p=s' => \$opts{project_dir},    # string
        'genome|g=s'      => \$opts{genome},         # string
        'help|?'          => \$opts{help},           # flag
        'man'             => \$opts{man},            # flag
        'debug=i'         => \$opts{debug},          # integer
        'verbose'         => \$opts{verbose},        # flag
        'version|v'       => sub {
            say "$0 Version $version";
            exit;
        }
    ) or pod2usage(2);

    # Now do usage checks
    pod2usage(1) if $opts{help};
    pod2usage(-verbose => 2, -exitval => 0) if $opts{man};

    # Check for input file
    pod2usage(
        -message => "Please specify a valid input file -i <in>\n",
        -exitval => 1
    ) if (!defined $opts{filein} or !-f $opts{filein});

    # Check for genome
    pod2usage(
        -message => "Please specify a valid reference genome --genome <hg19|hg38>\n",
        -exitval => 1
    ) unless ($opts{genome});

    # Check for format
    if (defined $opts{format}) {
        unless (
            $opts{format} eq FORMAT_BFF
            || $opts{format} eq FORMAT_JSON
            || $opts{format} eq FORMAT_HASH
        ) {
            pod2usage(
                -message => "Please specify a valid format -f bff|json|hash\n",
                -exitval => 1
            );
        }
    }

    # Check for dataset-id
    pod2usage(
        -message => "Please specify -dataset-id\n",
        -exitval => 1
    ) unless ($opts{dataset_id});

    # Check for project-dir
    pod2usage(
        -message => "Please specify -project-dir\n",
        -exitval => 1
    ) unless ($opts{project_dir});

    return \%opts;
}

###############################################################################
# Below subroutines remain mostly unchanged, except for a few minor warnings. #
###############################################################################

sub parse_header_snpeff {
    my $line = shift;

    # SnpEff annotation (ANN field) - parse the line from VCF header
    chomp $line;
    $line =~ s/##INFO=<ID=ANN,Number=.,Type=String,Description="Functional annotations: //;
    $line =~ s/ +//g;
    $line =~ s/'//g;
    $line =~ s/">//;
    $line =~ tr/\//_/;
    my @fields = split '\|', $line;
    die "[vcf2bff] Sorry, we could not load SnpEff fields from <vcf> header"
      unless @fields;
    return wantarray ? @fields : \@fields;
}

sub parse_header_samples {
    my ( $line, $start_col_samples ) = @_;
    chomp $line;
    my @fields = split /\t/, $line;
    @fields = @fields[ $start_col_samples .. $#fields ]
      or die "[vcf2bff] Sorry, we could not load SAMPLES from VCF header";

    # Build sample index => sample name
    my %sample_id = map { $_, $fields[$_] } ( 0 .. $#fields );
    return wantarray ? %sample_id : \%sample_id;
}

sub parse_info_field {
    my ( $info_field, $uid ) = @_;

    # Many fields are not key=value but we want to store them in a hash
    # If a field has no '=', give it a dummy value
    my @info_fields      = split /;/, $info_field;
    my @info_norm_fields;
    for my $inf (@info_fields) {
        $inf .= '=dummy' if $inf !~ /=/;
        push @info_norm_fields, split /=/, $inf;
    }
    # Must be pairs
    die "[vcf2bff] parse_info_field: uneven field count for $uid: @info_norm_fields"
      if @info_norm_fields % 2 != 0;

    my %info_hash = @info_norm_fields;
    return wantarray ? %info_hash : \%info_hash;
}

sub parse_ann_field {
    my ( $ann, $ann_field_data_loc, $n_snpeff_fields, $uid, $alt, $DEFAULT ) = @_;

    # SnpEff's ANN might have multiple alt alleles, separated by commas
    my @ann_alt_alleles = split /,/, $ann;
    my $ann_field;

    for my $ann_alt_allele (@ann_alt_alleles) {
        my @ann_fields = split /\|/, $ann_alt_allele;

        # Build a hash with 'Gene_Name' => 'value'
        my %ann_hash =
          map { $ann_field_data_loc->{$_}, ( $ann_fields[$_] // $DEFAULT ) }
          ( 0 .. $n_snpeff_fields );

        my $alt_allele = $ann_fields[0]; # The first entry is the actual ALT allele
        push @{ $ann_field->{$alt_allele} }, \%ann_hash;
    }

    return $ann_field;
}

sub prune_genotypes {
    my $arg       = shift;
    my $genotypes = $arg->{gt};
    my $sample_id = $arg->{sample_id};
    my $format    = $arg->{format};

    # We parse the FORMAT column (e.g. GT:GQ:DP)
    my @format_fields = split /:/, $format;
    my %format_field  = map { $format_fields[$_], $_ } 0 .. $#format_fields;
    my $n_format      = scalar @format_fields;

    my $pruned_genotypes;
    my $calls = 0;

    # We'll only store calls that contain '1' (variant)
    for my $i ( 0 .. $#{$genotypes} ) {
        my $tmp_ref;

        if ( $n_format == 1 ) {
            # e.g. just GT
            next unless $genotypes->[$i] =~ tr/1//;
            $tmp_ref = { $sample_id->{$i} => { GT => $genotypes->[$i] } };
        }
        else {
            # e.g. GT:GQ:DP
            $genotypes->[$i] =~ m/^(.*?):/;
            next unless $1 =~ tr/1//;
            my @fields = split /:/, $genotypes->[$i];
            while ( my ( $key, $val ) = each %format_field ) {
                # Store only fields that exist in the genotype line
                $tmp_ref->{ $sample_id->{$i} }{$key} = $fields[$val]
                  if defined $fields[$val] && length $fields[$val];
            }
        }
        $calls++;
        push @{$pruned_genotypes}, $tmp_ref if $tmp_ref;
    }

    return ( $pruned_genotypes, $calls );
}

sub guess_variant_type {
    my ( $ref, $alt ) = @_;
    return length($ref) == length($alt) ? 'SNP' : 'INDEL';
}

sub split_indels {
    my ( $start, $ref, $alt ) = @_;
    my $end  = $start;
    my $type = length($ref) > length($alt) ? 'DEL' : 'INS';
    $end += length($ref) - length($alt) if $type eq 'DEL';
    return ( $type, $end );
}

sub _parse_structural_variants {
    # (Unused)
}

=head1 NAME

vcf2bff: A script for parsing annotated vcf files and transforming the data to the format needed for Beacon v2.

=head1 SYNOPSIS

vcf2bff.pl -i <vcf_file> [-arguments|-options]

     Arguments:                       
       -i|input                       Annotated vcf file
       -f|format                      Output format [>bff|hash|json]
       -p|project-dir                 Beacon project dir
       -d|dataset-id                  Dataset ID
       -g|genome                      Reference genome

     Options:
       -h|help                        Brief help message
       -man                           Full documentation
       -debug                         Print debugging (from 1 to 5, being 5 max)
       -verbose                       Verbosity on


=head1 CITATION

The author requests that any published work that utilizes B<B2RI> includes a cite to the following reference:

Rueda, M, Ariosa R. "Beacon v2 Reference Implementation: a toolkit to enable federated sharing of genomic and phenotypic data". I<Bioinformatics>, btac568, https://doi.org/10.1093/bioinformatics/btac568

=head1 SUMMARY

Script to parse a VCF having SnepEff/SnpSift annotations.

The output can be:

       a) genomicVariantsVcf.json.gz [bff]
       b) Standard JSON [json]
       c) Perl hash data structure [hash]


=head1 INSTALLATION

This script should come preinstalled with C<beacon2-ri-tools>. Otherwise use the C<cpanfile> from ..

 $ sudo apt-get install libperlio-gzip-perl
 $ cpanm --installdeps ../..

=head1 HOW TO RUN VCF2BFF

For executing vcf2bff you will need:

=over

=item 1 - Input file

VCF file.

=item 2 - Dataset ID

String.

=item 3 - Reference genome

String.

=back

From version **2.0.8** we have a C<config.yaml> file with the data for C<annotatedWith>.

B<Examples:>

 ./vcf2bff.pl -i file.vcf.gz --dataset-id my_id_1 --genome hg19
 ./vcf2bff.pl -i file.vcf.gz --id my_id_1 -g hg19 -verbose log 2>&1

 nohup $path/vcf2bf.pl -i file.vcf.gz -debug 5 --dataset-id my_id_1 --genome hg19


=head1 AUTHOR 

Written by Manuel Rueda, PhD. Info about CNAG can be found at L<https://www.cnag.eu>.

Credits: Toshiaki Katayamai & Dietmar Fernandez-Orth for creating an initial Ruby/R version L<https://github.com/ktym/vcftobeacon> 
from which I borrowed the concept for creating vcf2bff.pl.

=head1 COPYRIGHT

This PERL file is copyrighted. See the LICENSE file included in this distribution.

=cut
