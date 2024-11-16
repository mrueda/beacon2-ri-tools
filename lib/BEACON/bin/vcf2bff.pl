#!/usr/bin/env perl
#
#   Script to parse a VCF having SnepEff/SnpSift annotations
#   The output can be:
#       a) genomicVariantsVcf.json.gz [bff]
#       b) Standard JSON [json] (STDOUT)
#       c) Perl hash data structure [hash] (STDOUT)
#
#   Last Modified: Nov/26/2023
#
#   Version taken from $beacon
#
#   Copyright (C) 2021-2024 Manuel Rueda (manuel.rueda@cnag.eu)
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
use FindBin qw($Bin);
use lib $Bin;
use BFF qw(%chr_name_conv %vcf_data_loc);

$Data::Dumper::Sortkeys = 1;

#$Data::Dumper::Sortkeys = sub {
#    no warnings 'numeric';
#    [ sort { $a <=> $b } keys %{ $_[0] } ];
#};

### Main ###
vcf2bff();
############
exit;

sub vcf2bff {

    # Defining a few variables
    my $version  = '2.0.1';
    my $DEFAULT  = '.';
    my $exe_path = abs_path($0);
    my $cwd      = cwd;
    my $user     = $ENV{LOGNAME} || $ENV{USER} || getpwuid($<);
    chomp( my $ncpuhost = qx{/usr/bin/nproc} ) // 1;
    $ncpuhost = 0 + $ncpuhost;    # coercing it to be a number
    my $format  = 'bff';                            # Default value
    my $fileout = 'genomicVariationsVcf.json.gz';
    my $skip_structural_variation = 1;

    # Defining <clinicalInterpretations.annotatedWith> to be used later
    my $annotated_with = {
        toolName       => 'SnpEff',
        version        => '5.0',
        toolReferences => {
            'bio.toolsId' => 'https://bio.tools/snpeff',
            url           => 'https://pcingola.github.io/SnpEff',
            databases     => {
                ClinVar => {
                    url =>
'https://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh37/archive_2.0/2021',
                    version => '20211218'
                },
                COSMIC => {
                    url =>
                      'https://cosmic-blog.sanger.ac.uk/cosmic-release-v92',
                    version => 'COSMICv92'
                },
                dbSNSFP => {
                    url     => 'https://sites.google.com/site/jpopgen/dbNSFP',
                    version => 'dbNSFP4.1a'
                }
            }
        }
    };

    # Variables for debug|verbose
    my $prompt = 'Info:';
    my $spacer = '*' x 28;
    my $arrow  = '=>';
    my $author = 'Manuel Rueda, PhD';

    # Reading arguments
    GetOptions(
        'input|i=s'       => \my $filein,                              # string
        'format|f=s'      => \$format,                                 # string
        'dataset-id|d=s'  => \my $dataset_id,                          # string
        'project-dir|p=s' => \my $project_dir,                         # string
        'genome|g=s'      => \my $genome,                              # string
        'help|?'          => \my $help,                                # flag
        'man'             => \my $man,                                 # flag
        'debug=i'         => \my $debug,                               # integer
        'verbose'         => \my $verbose,                             # flag
        'version|v'       => sub { say "$0 Version $version"; exit; }
    ) or pod2usage(2);
    pod2usage(1)                              if $help;
    pod2usage( -verbose => 2, -exitval => 0 ) if $man;
    pod2usage(
        -message => "Please specify a valid input file -i <in>\n",
        -exitval => 1
    ) if ( !-f $filein );
    pod2usage(
        -message =>
          "Please specify a valid reference genome --genome <hg19|hg38>\n",
        -exitval => 1
    ) unless ($genome);
    pod2usage(
        -message => "Please specify a valid format -f bff|json|hash\n",
        -exitval => 1
    ) unless ( $format eq 'bff' || $format eq 'json' || $format eq 'hash' );
    pod2usage(
        -message => "Please specify -dataset-id\n",
        -exitval => 1
    ) unless ($dataset_id);
    pod2usage(
        -message => "Please specify -project-dir\n",
        -exitval => 1
    ) unless ($project_dir);

    # We tell Perl to flush right away STDOUT data ($debug || $verbose)
    $| = 1 if ( $debug || $verbose );

    # We load user parameters on a hash
    my %param = (
        user       => $user,
        hostname   => hostname,
        cwd        => $cwd,
        projectDir => $project_dir,
        version    => $version,
        ncpuhost   => $ncpuhost,
        filein     => $filein,
        fileout    => $fileout
    );

    my %serialize =
      ( bff => 'data2bff', json => 'data2json', hash => 'data2hash' );
    my $serialize = $serialize{$format};

    if ( $debug || $verbose ) {
        say
"$prompt\n$prompt vcf2bff $version\n$prompt vcf2bff exe $exe_path\n$prompt Author: $author\n$prompt";
        say "$prompt ARGUMENTS USED:";
        say "$prompt --i $filein";
        say "$prompt --genome $genome";
        say "$prompt --format $format";
        say "$prompt --dataset-id $dataset_id";
        say "$prompt --project-dir $project_dir";
        say "$prompt --debug $debug" if $debug;
        say "$prompt --verbose"      if $verbose;
        say "$prompt\n$prompt VCF2BFF PARAMETERS:";
        my $param = '';
        $~ = "PARAMS";

        foreach $param ( sort keys %param ) {
            write;
        }

        format PARAMS =
@|||||@<<<<<<<<<<<<<<<< @<< @<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$prompt, $param, $arrow, $param{$param}
.

        say "$prompt\n$prompt $spacer\n$prompt STARTING VCF2BFF";
    }

    #############################
    # NOTE ABOUT ANNOTATIONS    #
    #############################

    # The annotations come in 4 flavours:
    #
    #  1 - SnpEff  ===> {INFO}{ANN}{[ALT|ISOFORM]}{fields} <= ONLY ISOFORM AS WE SPLIT TO BIALLELIC
    #  2 - dbNSFP  ===> {INFO}{dbNSFP_field}
    #  3 - ClinVar ===> {INFO}{CLINVAR_field}
    #  4 - COSMIC  ===> {INFO}{COSMIC_field}
    #
    # Note that some fields are redundant among the three

    # Defining the keys that will be used as {$uid}{$key} later on
    # NB: We get rid of header SAMPLES because it won't be loaded BUT $vcf_data_loc{SAMPLES} will be used later for stats!!!!
    my @keys2load = grep { $_ ne 'SAMPLES' } keys %vcf_data_loc;

    ############################################
    #  START READING AND PARSING SNPEFF FILE   #
    ############################################

    # We will read and parse the input line by line

    # To avoid issues with ZIP layers we use gzip to rw gz files
    # See: https://perldoc.perl.org/IO::Compress::FAQ
    #      https://www.biostars.org/p/94240/
    #open my $fh_in, '-|', 'zcat', $filein;
    open my $fh_in,  '<:gzip', $filein;
    open my $fh_out, '>:gzip', $fileout;
    say $fh_out "[";

    # Number of variants
    my $count = 0;

    # Variables that will be used in the while loop
    my @snpeff_fields      = ();
    my %ann_field_data_loc = ();
    my %sample_id          = ();

    # Start reading
    while ( defined( my $line = <$fh_in> ) ) {

        # Process header
        if ( $line =~ /^#/ ) {

            # Define data location for SnpEff
            @snpeff_fields = parse_header_snpeff($line)
              if $line =~ /^##INFO=<ID=ANN,Number/;

            # Loadign a hash with locations of fields as '0' => 'Allele', '1' => 'Annotation', etc.
            %ann_field_data_loc =
              map { $_, $snpeff_fields[$_] } ( 0 .. $#snpeff_fields );

            # Read VCF header to get SAMPLE IDs
            %sample_id = parse_header_samples( $line, $vcf_data_loc{SAMPLES} )
              if $line =~ /^#CHR/;

        }

        # Process variants
        else {

            # Number of variants++
            $count++;

            ####################################
            # Start ad hoc solutions to errors #
            ####################################

            # In case we need to fix something at this level
            #$line =~ s/Foo/Bar/;

            ##################################
            # End ad hoc solutions to errors #
            ##################################

            # All right, let's go!
            chomp $line;
            my @vcf_fields = split /\t/, $line; # NB: The split function does not consume time regardless of #samples

            # Transform $vcf_fields[0-9] into a hash to simplify naming
            # of common positions (e.g., $vcf_fields[ $vcf_data_loc{QUAL} ] ==> $vcf_fields_short{QUAL}
            my %vcf_fields_short = ();
            for my $key (@keys2load) {
                $vcf_fields_short{$key} = $vcf_fields[ $vcf_data_loc{$key} ];
            }

            # Create $uid => unique identifier for each variant (internal use)
            # E.g.,  $uid = 'chr7_10000_C_T'
            my $uid = 'chr'
              . $vcf_fields_short{CHROM} . '_'
              . $vcf_fields_short{POS} . '_'
              . $vcf_fields_short{REF} . '_'
              . $vcf_fields_short{ALT};

            # Skip Non-PASS variants (equally fast as grepping it above)
            #next unless $vcf_fields_short{QUAL} eq 'PASS';

            # Skip SV => e.g., "<INS:ME:ALU>" do not match alternateBases regex ^([ACGTUNRYSWKMBDHV\-\.]*)$.
            next
              if ( $vcf_fields_short{ALT} =~ m/^</
                && $skip_structural_variation );

            # SnpEff annotates multiple dbSNP id with ';'
            $vcf_fields_short{ID} =~ tr/;/,/;

            # We will load the VCF into a Hash of Hashes (HoH) data structure (ref $hash_out)
            #
            # VCF
            #  |-- INFO (%info_hash)
            #  |   |---- ANN (%ann_hash)
            #  |   |---- CRG (crg_hash);
            #  |   |---- GENE from header's ##INFO=<ID=GENE>

            ##################
            # VCF-INFO field #
            ##################
            my %info_hash = parse_info_field( $vcf_fields_short{INFO}, $uid );

            # INFO column may or may not have VT field
            $info_hash{VT} =
              guess_variant_type( $vcf_fields_short{REF},
                $vcf_fields_short{ALT} )
              unless ( exists $info_hash{VT} && $info_hash{VT} !~ m/,/ );

            # We store MULTI_ALLELIC at INFO level (if exists)
            $info_hash{MULTI_ALLELIC} =
              $line =~ m/;MULTI_ALLELIC;/ ? 'yes' : 'no';

            ######################
            # VCF-INFO-ANN field #
            ######################

            # We overwrite the existing $info_hash{ANN} string with a nested HoAoH
            # **Warning: SnpEff does not annotate CNVs (ANN field comes empty)
            $info_hash{ANN} =
              exists $info_hash{ANN}
              ? parse_ann_field( $info_hash{ANN}, \%ann_field_data_loc,
                $#snpeff_fields, $uid, $vcf_fields_short{ALT}, $DEFAULT )
              : undef;
            warn
"** WARNING: Skipping <$uid> because it does not have the field INFO=<ID=ANN>"
              and next
              unless defined $info_hash{ANN};

            ######################
            # VCF-INFO-CRG field #
            ######################

            # Note that after bctools norm the label for ALT in GT fields MUST be '1', no 0/2, 0/3. Otherwise our AC_MOD will be biased
            my @genotypes =
              @vcf_fields[ $vcf_data_loc{SAMPLES} .. $#vcf_fields ];

            # Now we transform the GT field into a nested data structure (AoHoH)
            my ( $pruned_genotypes, $n_calls ) = prune_genotypes(
                {
                    gt        => \@genotypes,
                    sample_id => \%sample_id,
                    format    => $vcf_fields_short{FORMAT}
                }
            );

            # Loading %crg_hash
            my %crg_hash = ();

            # We start by filling out $crg_hash{INFO} => <g_v.info>
            for my $key ( keys %param ) {
                $crg_hash{INFO}{vcf2bff}{$key} = $param{$key};
            }
            $crg_hash{INFO}{genome}    = $genome;
            $crg_hash{INFO}{datasetId} = $dataset_id;

            # Here we deal with two g_v terms:
            # 1 - caseLevelData.analysisId
            # 2 - variantLevelData.clinicalInterpretations.annotatedWith
            # We prepare them to be serialized later
            $crg_hash{ANNOTATED_WITH} = $annotated_with;

            # Miscellanea values (some are for internal use only)
            my $n_samples = scalar keys %sample_id;
            $crg_hash{SAMPLES_ALT}     = $pruned_genotypes;    # internal
            $crg_hash{N_SAMPLES_ALT}   = $n_calls;             # internal
            $crg_hash{N_SAMPLES}       = $n_samples;           # internal
            $crg_hash{CALLS_FREQUENCY} = sprintf "%10.8f",
              $crg_hash{N_SAMPLES_ALT} / $crg_hash{N_SAMPLES};    # internal
            $crg_hash{CUSTOM_VAR_ID} = $count;
            $crg_hash{REFSEQ} =
              $chr_name_conv{ $vcf_fields_short{CHROM} };
            $crg_hash{POS}    = $vcf_fields_short{POS};
            $crg_hash{ENDPOS} = $crg_hash{POS};

            # Load 0-based positions
            $crg_hash{POS_ZERO_BASED}    = $crg_hash{POS} - 1;
            $crg_hash{ENDPOS_ZERO_BASED} = $crg_hash{ENDPOS};

            # Nest %crg_hash to %info_hash
            $info_hash{CRG} = \%crg_hash;

            #################
            # LOAD HASH_OUT #
            #################

            # Now that we have all the data loaded in hashes, we merge all of them into
            # an unique ref hash named $hash_out. Note that $hash_out will have information per ONE variant.
            # We CANNOT STORE ALL VARIANTS IN ONE UNIQUE HASH, AS IT WILL REQUIRE A LOT OF MEMORY
            # WE ARE PRINTING LINE-BY-LINE
            my $hash_out = {};

            # The first level of the hash == VCF column level (@keys2load)
            foreach my $key (@keys2load) {

                # For the INFO COLUMN we have %info_hash
                #                             |-------- %crg_hash
                #                             |-------- %ann_hash
                $hash_out->{$uid}{$key} = do {
                    if   ( $key eq 'INFO' ) { \%info_hash }
                    else                    { $vcf_fields_short{$key} }
                }
            }

            #############################################
            #  PRINTING ACCORDING TO USER PARAMETERS    #
            #############################################

            # Initialize the object with data - Overhead time is negligible
            my $bff = BFF->new($hash_out);

            # Serialize the data structure to the desired format
            print $fh_out $bff->$serialize( $uid, $verbose );
            print $fh_out ",\n" unless eof;

            say "$prompt Variants processed = ", $count
              if ( ( $debug || $verbose ) && $count % 10_000 == 0 );

            #              if ( ( $debug || $verbose ) && $count % 100 == 0 );
        }
    }

    ##################################################
    #  END OF PRINTING ACCORDING TO USER PARAMETERS  #
    ##################################################

    say $fh_out "\n]";

    #########################################
    #  END READING AND PARSING SNPEFF FILE  #
    #########################################
    close $fh_in;
    close $fh_out;
    say "$prompt $spacer\n$prompt VCF2BFF FINISHED OK"
      if ( $debug || $verbose );
    return 1;
}

sub parse_header_snpeff {

    my $line = shift;

    # SnpEff annotion (ANN field)
    # ##INFO=<ID=ANN,Number=.,Type=String,Description="Functional annotations: 'Allele | Annotation | Annotation_Impact |\
    #  Gene_Name | Gene_ID | Feature_Type | Feature_ID | Transcript_BioType | Rank | HGVS.c | HGVS.p | cDNA.pos / cDNA.length |\
    #  CDS.pos / CDS.length | AA.pos / AA.length | Distance | ERRORS / WARNINGS / INFO'

    # Rank is # Exon or intron
    chomp $line;
    $line =~
s/##INFO=<ID=ANN,Number=.,Type=String,Description="Functional annotations: //;
    $line =~ s/ +//g;
    $line =~ s/'//g;
    $line =~ s/">//;
    $line =~ tr/\//_/;
    my @fields = split '\|', $line;
    die "Sorry, we could not load SnpEff fields from <vcf> header"
      unless @fields;
    return wantarray ? @fields : \@fields;
}

sub parse_header_samples {

    my ( $line, $start_col_samples ) = @_;
    chomp $line;
    my @fields = split /\t/, $line;
    @fields = @fields[ $start_col_samples .. $#fields ]; # Could not do the split in one step :-/
    die "Sorry, we could not load SAMPLES fields from <vcf> header"
      unless @fields;

    # %sample_id = ( '0' => 'sample1', '1' => 'sample2',..., sampleN)
    my %sample_id =
      map { $_, $fields[$_] } ( 0 .. $#fields );
    return wantarray ? %sample_id : \%sample_id;
}

sub parse_info_field {

    my ( $info_field, $uid ) = @_;

    # We have many fields that are not key/value but we want to build a hash.
    #   a) Pair  ===> if they m/=/ (i.e., key=value)
    #   b) Single ==> otherwise  ** For these we set a <dummy> value just to store them in the hash
    #     b1) If INFO field eq '.' then we'll get '.' => 'dummy

    my @info_fields      = split /;/, $info_field;
    my @info_norm_fields = ();
    for my $info_field (@info_fields) {    # modifies ori array
        $info_field .= '=dummy' if $info_field !~ /=/;
        push @info_norm_fields, split /\=/, $info_field;
    }
    die "$uid @info_norm_fields" if @info_norm_fields % 2 != 0;
    my %info_hash = @info_norm_fields;
    return wantarray ? %info_hash : \%info_hash;
}

sub parse_ann_field {

    my ( $ann, $ann_field_data_loc, $n_snpeff_fields, $uid, $alt, $DEFAULT ) =
      @_;

    # ANN: Comes from SnpEff and we must consider 2 scenarios:
    #     a) VCF was MULTIALLELIC
    #     b) VCF was BIALLELIC
    #
    # bcftools leaves intact ANN. Multiple alleles are separated by ','
    # thus we ALWAYS split the field into an array @ann_alt_alleles
    #
    # ANN=G|intergenic_region|MODIFIER|CHR_START-DUXAP8|CHR_START-DUXAP8|intergenic_region|CHR_START-DUXAP8|||n.16050075A>G||||||
    # We can have MULTI_ALLELIC variants and isoforms ==> C|x|y|z,T|x|y|z or C|x|y|z,C|i|j|k
    # which means multiple values for one key {ANN}{C} = [ann1, ann2, ..., annN], {ANN}{T} = [ann1]
    # For that reason we load the values as an array
    my @ann_alt_alleles = split /,/, $ann;
    my $ann_field;

    for my $ann_alt_allele (@ann_alt_alleles) {
        my @ann_fields = split /\|/, $ann_alt_allele;

        # We load %ann_hah in the form of 'Gene_Name' => 'value_resulting_from_split'
        # Note that we go from 0 .. $#snpeff_fields to fill ALL SNPEFF values
        my %ann_hash =
          map { $ann_field_data_loc->{$_}, ( $ann_fields[$_] // $DEFAULT ) }
          ( 0 .. $n_snpeff_fields );
        my $alt_allele = $ann_fields[0]; # IMPORTANT => All ANN correspond to the same ALT
        push( @{ $ann_field->{$alt_allele} }, \%ann_hash ); # Array of hashes (@AoH);
    }
    return $ann_field;
}

sub prune_genotypes {

    my $arg       = shift;
    my $genotypes = $arg->{gt};
    my $sample_id = $arg->{sample_id};
    my $format    = $arg->{format};

    # Parse FORMAT field
    my @format_fields = split /:/, $format;
    my %format_field  = map { $format_fields[$_], $_ } ( 0 .. $#format_fields );
    my $n_format      = scalar @format_fields;

    my $pruned_genotypes;
    my $calls = 0;

    #   my $nocall_regex = qr#\.[/\|]\.#;               # No call must be ./. or .|.
    #   my $zerozero_regex = qr#0[/\|]0#;

    # We will only load values for <Call> or <Half call> GT
    for my $i ( 0 .. $#{$genotypes} ) {

        my $tmp_ref;

        # GT
        if ( $n_format == 1 ) {
            next unless $genotypes->[$i] =~ tr/1//;
            $tmp_ref = { $sample_id->{$i} => { GT => $genotypes->[$i] } };
        }

        # GT:GQ:DP:HQ
        else {
            $genotypes->[$i] =~ m/^(.*?):/;    #  GT:
            next unless $1   =~ tr/1//;
            my @fields = split /:/, $genotypes->[$i];
            while ( my ( $key, $val ) = each %format_field ) {
                $tmp_ref->{ $sample_id->{$i} }{$key} = $fields[$val]
                  if $fields[$val];
            }
        }

        # Increment number of called GT
        $calls++;

        # Finally load the array
        push @{$pruned_genotypes}, $tmp_ref;
    }
    return ( $pruned_genotypes, $calls );
}

sub guess_variant_type {

    # Two scenarios:
    #  1 - The VT field was empty
    #  2 - The VT was introduced BEFORE spliting to biallelic e.g., 'VT=SNP,INDEL'
    my ( $ref, $alt ) = @_;
    my $type = length($ref) == length($alt) ? 'SNP' : 'INDEL';
    return $type;
}

sub split_indels {

    my ( $start, $ref, $alt ) = @_;
    my $end  = $start;
    my $type = length($ref) > length($alt) ? 'DEL' : 'INS';
    $end += length($ref) - length($alt) if $type eq 'DEL';
    return ( $type, $end );
}

sub _parse_structural_variants {

    #

    # Set up a new field $crg_hash{VT_MOD} that will contains INS/DEL or SVTYPE (e.g., CNV)
    #            $crg_hash{VT_MOD} = $info_hash{VT};    # svType
    #
    #           # Now we check for presences of commas in VT field such as VT=SNP,INDEL
    #            if ( $crg_hash{VT_MOD} =~ m/,/ ) {
    #                die
    #"$uid VT field has commas and is not SNP|INDEL $crg_hash{VT_MOD}"
    #                  if $crg_hash{VT_MOD} !~ m/SNP|INDEL/;
    #
    #                # Return values can be SNP or INDEL only
    #                $crg_hash{VT_MOD} = guess_variant_type( $vcf_fields_short{REF},
    #                    $vcf_fields_short{ALT} );
    #            }
    #
    #            # Split INDELS into INS / DEL
    #            if ( $crg_hash{VT_MOD} eq 'INDEL' ) {
    #                my ( $var_type, $pos_end ) =
    #                  split_indels( $vcf_fields_short{POS}, $vcf_fields_short{REF},
    #                    $vcf_fields_short{ALT} );
    #                $crg_hash{VT_MOD} = $var_type;
    #                $crg_hash{ENDPOS} = $pos_end;
    #            }
    #
    #            # Load information relative only to SV
    #            # VT     = SV
    #            # SVLEN is vLength
    #            # SVTYPE = (ALU CNV DEL DUP INS INV LINE1)
    #            if ( $info_hash{VT} eq 'SV' ) {
    #                $crg_hash{VT_MOD} = 'SV_' . $info_hash{SVTYPE};
    #                $crg_hash{ENDPOS} =
    #                    exists $info_hash{END} ? $info_hash{END}
    #                  : exists $info_hash{SVLEN}
    #                  ? $crg_hash{POS} + $info_hash{SVLEN}
    #                  : $DEFAULT;
    #            }
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

The author requests that any published work that utilizes B<B2RI> includes a cite to the the following reference:

Rueda, M, Ariosa R. "Beacon v2 Reference Implementation: a toolkit to enable federated sharing of genomic and phenotypic data". I<Bioinformatics>, btac568, https://doi.org/10.1093/bioinformatics/btac568

=head1 SUMMARY

Script to parse a VCF having SnepEff/SnpSift annotations

The output can be:

       a) genomicVariantsVcf.json.gz [bff]
       b) Standard JSON [json]
       c) Perl hash data structure [hash]


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

B<Examples:>

./vcf2bff.pl -i file.vcf.gz --dataset-id my_id_1 --genome hg19

./vcf2bff.pl -i file.vcf.gz  --id my_id_1 -g hg19 -verbose log 2>&1

nohup $path/vcf2bf.pl -i file.vcf.gz -debug 5 --dataset-id my_id_1 --genome hg19


=head1 AUTHOR 

Written by Manuel Rueda, PhD. Info about CNAG can be found at L<https://www.cnag.eu>.

Credits: Toshiaki Katayamai & Dietmar Fernandez-Orth for creating an initial Ruby/R version L<https://github.com/ktym/vcftobeacon> 
from which I borrowed the concept for creating vcf2bff.pl.

=head1 REPORTING BUGS

Report bugs or comments to L<manuel.rueda@cnag.eu>.


=head1 COPYRIGHT

This PERL file is copyrighted. See the LICENSE file included in this distribution.

=cut
