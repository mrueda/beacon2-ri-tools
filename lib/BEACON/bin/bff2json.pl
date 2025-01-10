#!/usr/bin/env perl
#
#   Script that parses <genomicVariationsVCF.json.gz> for jQuery's DataTables
#
#   The output can be:
#     a) hash (unmodified)
#     b) json (unmodified) NDJSON
#     c) json4html (the json objects are converted to a json-array w/urls but w/o key values)
#
#   Last Modified: Apr/12/2022
#
#   Version taken from $beacon
#
#   Copyright (C) 2021-2025 Manuel Rueda (manuel.rueda@cnag.eu)
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
use Data::Dumper;
use Path::Tiny;
use JSON::XS;

#### Main ####
bff2json();
##############
exit;

sub bff2json {

    # Defining a few variables
    my $version = '2.0.0';
    my $DEFAULT = '.';
    my $format  = 'json';    # Default value

    # Reading arguments
    GetOptions(
        'input|i=s'  => \my $filein,                               # string
        'format|f=s' => \$format,                                  # string
        'help|?'     => \my $help,                                 # flag
        'man'        => \my $man,                                  # flag
        'debug=i'    => \my $debug,                                # integer
        'verbose'    => \my $verbose,                              # flag
        'version|v'  => sub { say "$0 Version $version"; exit; }
    ) or pod2usage(2);
    pod2usage(1)                              if $help;
    pod2usage( -verbose => 2, -exitval => 0 ) if $man;
    pod2usage(
        -message => "Please specify a valid input file -i <file.bff>\n",
        -exitval => 1
    ) if ( !-f $filein );
    my %func = (
        hash      => \&serialize2hash,
        json      => \&serialize2json,
        json4html => \&serialize2json4html
    );
    pod2usage(
        -exitval => 1,
        -verbose => 1,
        -message => "Unknown format $format"
    ) unless exists $func{$format};

    #################################
    #     START READING BFF FILE    #
    #################################
    my $fh = path($filein)->openr_utf8;

    my @variants = ();
    while ( my $line = <$fh> ) {

        #next if $line =~ m/^[\[|\]]$/;
        chomp $line;                     # \
        chop $line if $line =~ m/,$/;    #  (last line does not have comma)
        my $row = decode_json($line);    # Decode to Perl data structure

        # Store as an array and print at the end if json4html
        if ( $format eq 'json4html' ) {
            push @variants, $func{$format}->($row);
        }

        # Print otherwise
        else {
            $func{$format}->($row);
        }
    }
    close $fh;

    ##############################
    #     END READING BFF FILE   #
    ##############################

    # Print @variants if json4html
    print '{"data":[', ( join ',', @variants ), "]}\n"
      if $format eq 'json4html';
    say "Finished OK" if ( $debug || $verbose );
    return 1;
}

sub serialize2hash {

    my $data = shift;
    $Data::Dumper::Sortkeys = 1;    # In alphabetic order
    print Dumper $data;
}

sub serialize2json {

    # NDJSON (Newline Delimited JSON)
    my $data  = shift;
    my $coder = JSON::XS->new->utf8->canonical->pretty;
    my $json  = $coder->encode($data);
    print $json;
}

sub serialize2json4html {

    my $data = shift;
    my $hash;

    # Note 041222: using deprecated <_position> to get <assemblyId> and <refseqId>
    $hash->{variantInternalId} = $data->{variantInternalId};
    $hash->{assemblyId}        = $data->{_position}{assemblyId};
    $hash->{refseqId}          = $data->{_position}{refseqId};
    my $position = $data->{variation}{location}{interval}{start}{value}; # 0-based
    my $tmp_str = $data->{_position}{refseqId} . '-' . ( $position + 1 ) . '-' # from 0-based to 1-based (gnomAD)
      . $data->{variation}{referenceBases} . '-'
      . $data->{variation}{alternateBases};
    $hash->{position} = 0 + $position;    # coercing it to number
    $hash->{referenceBases} = $data->{variation}{referenceBases};
    $hash->{alternateBases} =
      parse_gnomad( $tmp_str, $data->{variation}{alternateBases} );
    $hash->{variantType}   = $data->{variation}{variantType};
    $hash->{genomicHGVSId} = $data->{identifiers}{genomicHGVSId};
    $hash->{geneIds}       = join ',',
      map { parse_gene($_) } @{ $data->{molecularAttributes}{geneIds} };
    $hash->{molecularEffects} = join ',',
      map { parse_molecular_effects( $_->{label} ) }
      @{ $data->{molecularAttributes}{molecularEffects} };
    $hash->{aminoacidChanges} = join ',',
      @{ $data->{molecularAttributes}{aminoacidChanges} };
    $hash->{annotationImpact} = join ',',
      map { parse_annotation_impact($_) }
      @{ $data->{molecularAttributes}{annotationImpact} };
    $hash->{conditionId} = join ',',
      map { "$_->{effect}{label}($_->{effect}{id})" }
      @{ $data->{variantLevelData}{clinicalInterpretations} };
    $hash->{clinicalRelevance} = join ',',
      map { parse_clinical_relevance( $_->{clinicalRelevance} ) }
      ( grep { $_->{clinicalRelevance} }
          @{ $data->{variantLevelData}{clinicalInterpretations} } );
    $hash->{dbSNP} = join ',',
      map { parse_dbsnp( $_->{id} ) }
      ( grep { $_->{id} =~ /dbSNP:/ }
          @{ $data->{identifiers}{variantAlternativeIds} } );
    $hash->{ClinVar} = join ',',
      map { parse_clinvar( $_->{id} ) }
      ( grep { $_->{id} =~ /ClinVar:/ }
          @{ $data->{identifiers}{variantAlternativeIds} } );
    $hash->{biosampleId} = join ',',
      map { parse_biosample_id($_) } @{ $data->{caseLevelData} }
      if scalar @{ $data->{caseLevelData} };

    # Ad hoc terms
    for my $term (qw(QUAL FILTER)) {
        $hash->{$term} = $data->{variantQuality}{$term};
    }

    #  dbSNP ids come from => 'variantId'
    #  parse_rs( $variants[$i][ $header_data_loc{variantId} ] );

    # **** IMPORTANT *****
    # dataTables DOES NOT NEED KEY NAME and works with ARRAYS
    my @browser_fields =
      qw(variantInternalId assemblyId refseqId position referenceBases alternateBases QUAL FILTER variantType genomicHGVSId geneIds molecularEffects aminoacidChanges annotationImpact conditionId dbSNP ClinVar clinicalRelevance biosampleId);
    my $array;
    for my $key (@browser_fields) {
        push @$array, $hash->{$key};
    }

    # Serialize
    my $coder = JSON::XS->new->utf8;
    my $json  = $coder->encode($array);

    # prunning (for dataTables|JQuery)
    $json =~ tr/{}/[]/;
    return $json;
}

sub parse_dbsnp {

    my $id        = shift;
    my $dbsnp_url = 'https://www.ncbi.nlm.nih.gov/snp';
    $id =~ s/dbSNP://;
    my $id_str =
      $id =~ /\w+/ ? qq(<a target="_blank" href="$dbsnp_url/$id">$id</a>) : $id;
    return $id_str;
}

sub parse_clinvar {

    my $id          = shift;
    my $clinvar_url = 'https://www.ncbi.nlm.nih.gov/clinvar/variation/';
    $id =~ s/ClinVar://;
    my $id_str =
      $id =~ /\d+/
      ? qq(<a target="_blank" href="$clinvar_url/$id">$id</a>)
      : $id;
    return $id_str;
}

sub parse_gene {

    my $str   = shift;
    my @genes = split /,/, $str;
    my $gene_url = 'https://www.genecards.org/cgi-bin/carddisp.pl?gene='; # Gene Symbol
    my @genes_url = ();
    for my $gene (@genes) {
        my $gene_str =
          $gene =~ /\w+/
          ? qq(<a target="_blank" href="${gene_url}${gene}">$gene</a>)
          : $gene;
        push @genes_url, $gene_str;
    }
    return join ',', @genes_url;
}

sub parse_gnomad {

    # Only bi-allelic variants (no need to split)
    my ( $str, $alt ) = @_;
    my $gnomad_url = 'https://gnomad.broadinstitute.org/variant';
    return qq(<a target="_blank" href="$gnomad_url/$str">$alt</a>);
}

sub parse_clinical_relevance {

    my $str   = shift;
    my %color = (
        'benign'                 => 'success',
        'likely benign'          => 'info',
        'uncertain significance' => 'inverse',
        'likely pathogenic'      => 'warning',
        'pathogenic'             => 'danger'
    );
    my $str_class =
      exists $color{$str}
      ? qq(<span class="btn btn-$color{$str} disabled">$str</span>)
      : $str;
    return $str_class;
}

sub parse_molecular_effects {

    my $str   = shift;
    my %color = (
        synonymous    => 'success',
        missense      => 'inverse',
        upstream      => 'warning',
        downstream    => 'warning',
        non_coding    => 'warning',
        '5_prime_UTR' => 'warning',
        '3_prime_UTR' => 'warning',
        intron        => 'warning',
        frameshift    => 'warning',
        stop_gained   => 'error',
        nonsense      => 'error'
    );

    my $match = '';
    for my $key ( keys %color ) {
        $match = $key and last if $str =~ m/^$key/;
    }
    my $str_class =
      $match ? qq(<span class="text-$color{$match}">$str</span>) : $str;
    return $str_class;
}

sub parse_annotation_impact {

    my $str   = shift;
    my %color = (
        LOW      => 'success',
        MODERATE => 'inverse',
        MODIFIER => 'warning',
        HIGH     => 'error'
    );
    my $str_class = qq(<span class="text-$color{$str}">$str</span>);
    return $str_class;
}

sub parse_biosample_id {

    my $data         = shift;
    my $biosample_id = $data->{biosampleId};
    my $zygosity     = $data->{zygosity}{label};
    my $depth        = $data->{DP};
    return $data->{DP}
      ? "$biosample_id($zygosity:$depth)"
      : "$biosample_id($zygosity)";
}

=head1 NAME

bff2json: A script that parses BFF files and serializes it to json/hash data structures.


=head1 SYNOPSIS


bff2json.pl -i <file.bff> [-arguments|-options]

     Arguments:                       
       -i|input                       BFF file
       -f|format                      Output format [>json|hash]

     Options:
       -h|help                        Brief help message
       -man                           Full documentation
       -debug                         Print debugging (from 1 to 5, being 5 max)
       -verbose                       Verbosity on


=head1 CITATION

The author requests that any published work that utilizes B<B2RI> includes a cite to the the following reference:

Rueda, M, Ariosa R. "Beacon v2 Reference Implementation: a toolkit to enable federated sharing of genomic and phenotypic data". I<Bioinformatics>, btac568, https://doi.org/10.1093/bioinformatics/btac568

=head1 SUMMARY

bff2json: A script that parses BFF files and serializes it to json/hash data structures.

=head1 HOW TO RUN BFF2JSON

The script runs on Linux (tested on Debian-based distribution). Perl 5 is installed by default on Linux, 
but you might need to manually install a couple CPAN modules.

    * JSON::XS

First we install cpanminus (with sudo privileges):

   $ sudo apt-get install cpanminus

Then the modules:

   $ cpanm --sudo JSON::XS

For executing bff2json you will need:

=over

=item Input file

file3.bff.gz

=back

B<Examples:>

   $ ./bff2json.pl -i file3.bff.gz > file.json

   $ $path/bff2json.pl -i file3.bff.gz -format hash > file.txt


=head1 AUTHOR 

Written by Manuel Rueda, PhD. Info about CNAG can be found at L<https://www.cnag.eu>.

=head1 REPORTING BUGS

Report bugs or comments to <manuel.rueda@cnag.eu>.


=head1 COPYRIGHT

This PERL file is copyrighted. See the LICENSE file included in this distribution.

=cut
