#!/usr/bin/env perl

use strict;
use warnings;
use autodie;
use feature qw(say);
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;
use Path::Tiny;
use JSON::XS;

#--------------------------------------------------
# Global variables/metadata
#--------------------------------------------------
my $VERSION = '2.0.8';

#--------------------------------------------------
# "Main" entry point
#--------------------------------------------------
bff2json();
exit;

#--------------------------------------------------
# MAIN SUBROUTINE
#--------------------------------------------------
sub bff2json {
    my ($args) = parse_command_line();

    # Prepare the dispatch table for formats
    my %format_dispatch = (
        hash      => \&serialize2hash,
        json      => \&serialize2json,
        json4html => \&serialize2json4html,
    );

    # Validate format
    pod2usage(
        -exitval => 1,
        -verbose => 1,
        -message => "Unknown format '$args->{format}'\n"
    ) unless exists $format_dispatch{ $args->{format} };

    # Read and process file
    my @variants;
    my $fh = path( $args->{filein} )->openr_utf8;
    while ( my $line = <$fh> ) {
        chomp $line;
        chop $line if $line =~ m/,$/;    # remove trailing commas

        # Decode to Perl data structure
        my $row = decode_json($line);

        # For json4html, we store first and print at the end
        if ( $args->{format} eq 'json4html' ) {
            push @variants, $format_dispatch{ $args->{format} }->($row);
        }
        else {
            # Otherwise, we emit line-by-line
            $format_dispatch{ $args->{format} }->($row);
        }
    }
    close $fh;

    # If format is json4html, print the final combined JSON
    if ( $args->{format} eq 'json4html' ) {
        print '{"data":[', ( join ',', @variants ), "]}\n";
    }

    say "Finished OK" if ( $args->{debug} || $args->{verbose} );

    return 1;
}

#--------------------------------------------------
# Parse command line options
#--------------------------------------------------
sub parse_command_line {
    my $format  = 'json';    # default
    my $help    = 0;
    my $man     = 0;
    my $debug   = 0;
    my $verbose = 0;
    my $filein;

    GetOptions(
        'input|i=s'  => \$filein,
        'format|f=s' => \$format,
        'help|?'     => \$help,
        'man'        => \$man,
        'debug=i'    => \$debug,
        'verbose'    => \$verbose,
        'version|v'  => sub {
            say "$0 Version $VERSION";
            exit;
        },
    ) or pod2usage(2);

    pod2usage(1)                              if $help;
    pod2usage( -verbose => 2, -exitval => 0 ) if $man;
    pod2usage(
        -message => "Please specify a valid input file: -i <file.bff>\n",
        -exitval => 1
    ) if ( !defined $filein or !-f $filein );

    return {
        filein  => $filein,
        format  => $format,
        debug   => $debug,
        verbose => $verbose,
    };
}

#--------------------------------------------------
# Serializers
#--------------------------------------------------
sub serialize2hash {
    my ($data) = @_;
    $Data::Dumper::Sortkeys = 1;    # In alphabetic order
    print Dumper($data);
}

sub serialize2json {

    # NDJSON (Newline Delimited JSON)
    my ($data) = @_;
    my $coder = JSON::XS->new->utf8->canonical->pretty;
    print $coder->encode($data);
}

sub serialize2json4html {
    my ($data) = @_;

    # Build the small “hash” that we want for dataTables
    my %hash;
    $hash{variantInternalId} = $data->{variantInternalId};
    $hash{assemblyId}        = $data->{_position}{assemblyId};
    $hash{refseqId}          = $data->{_position}{refseqId};
    my $position = $data->{variation}{location}{interval}{start}{value};

    my $tmp_str =
        $data->{_position}{refseqId} . '-'
      . ( $position + 1 ) . '-'
      . $data->{variation}{referenceBases} . '-'
      . $data->{variation}{alternateBases};

    $hash{position}       = 0 + $position;                        # coerce to number
    $hash{referenceBases} = $data->{variation}{referenceBases};
    $hash{alternateBases} =
      parse_gnomad( $tmp_str, $data->{variation}{alternateBases} );
    $hash{variantType}   = $data->{variation}{variantType};
    $hash{genomicHGVSId} = $data->{identifiers}{genomicHGVSId};
    $hash{geneIds}       = join ',',
      map { parse_gene($_) } @{ $data->{molecularAttributes}{geneIds} };

    $hash{molecularEffects} = join ',',
      map { parse_molecular_effects( $_->{label} ) }
      @{ $data->{molecularAttributes}{molecularEffects} };

    $hash{aminoacidChanges} = join ',',
      @{ $data->{molecularAttributes}{aminoacidChanges} };

    $hash{annotationImpact} = join ',',
      map { parse_annotation_impact($_) }
      @{ $data->{molecularAttributes}{annotationImpact} };

    $hash{conditionId} = join ',',
      map { "$_->{effect}{label}($_->{effect}{id})" }
      @{ $data->{variantLevelData}{clinicalInterpretations} };

    $hash{clinicalRelevance} = join ',',
      map  { parse_clinical_relevance( $_->{clinicalRelevance} ) }
      grep { $_->{clinicalRelevance} }
      @{ $data->{variantLevelData}{clinicalInterpretations} };

    $hash{dbSNP} = join ',', map { parse_dbsnp( $_->{id} ) }
      grep { $_->{id} =~ /dbSNP:/ }
      @{ $data->{identifiers}{variantAlternativeIds} };

    $hash{ClinVar} = join ',', map { parse_clinvar( $_->{id} ) }
      grep { $_->{id} =~ /ClinVar:/ }
      @{ $data->{identifiers}{variantAlternativeIds} };

    if ( scalar @{ $data->{caseLevelData} } ) {
        $hash{biosampleId} = join ',',
          map { parse_biosample_id($_) } @{ $data->{caseLevelData} };
    }

    for my $term (qw(QUAL FILTER)) {
        $hash{$term} = $data->{variantQuality}{$term};
    }

    # Convert to array for jQuery DataTables
    my @browser_fields = qw(
      variantInternalId assemblyId refseqId position referenceBases
      alternateBases QUAL FILTER variantType genomicHGVSId geneIds
      molecularEffects aminoacidChanges annotationImpact conditionId
      dbSNP ClinVar clinicalRelevance biosampleId
    );

    my @array;
    for my $key (@browser_fields) {
        push @array, $hash{$key};
    }

    # Encode to JSON, then replace { } with [ ] for the dataTables format
    my $coder = JSON::XS->new->utf8;
    my $json  = $coder->encode( \@array );
    $json =~ tr/{}/[]/;
    return $json;
}

#--------------------------------------------------
# Parsers and small helpers
#--------------------------------------------------
sub parse_dbsnp {
    my ($id) = @_;
    my $dbsnp_url = 'https://www.ncbi.nlm.nih.gov/snp';
    $id =~ s/dbSNP://;
    return ( $id =~ /\w+/ )
      ? qq(<a target="_blank" href="$dbsnp_url/$id">$id</a>)
      : $id;
}

sub parse_clinvar {
    my ($id) = @_;
    my $clinvar_url = 'https://www.ncbi.nlm.nih.gov/clinvar/variation/';
    $id =~ s/ClinVar://;
    return ( $id =~ /\d+/ )
      ? qq(<a target="_blank" href="$clinvar_url/$id">$id</a>)
      : $id;
}

sub parse_gene {
    my ($str)    = @_;
    my $gene_url = 'https://www.genecards.org/cgi-bin/carddisp.pl?gene=';
    my @genes    = split /,/, $str;
    my @genes_url;
    for my $gene (@genes) {
        push @genes_url,
          ( $gene =~ /\w+/ )
          ? qq(<a target="_blank" href="${gene_url}${gene}">$gene</a>)
          : $gene;
    }
    return join ',', @genes_url;
}

sub parse_gnomad {
    my ( $str, $alt ) = @_;
    my $gnomad_url = 'https://gnomad.broadinstitute.org/variant';
    return qq(<a target="_blank" href="$gnomad_url/$str">$alt</a>);
}

sub parse_clinical_relevance {
    my ($str) = @_;
    my %color = (
        'benign'                 => 'success',
        'likely benign'          => 'info',
        'uncertain significance' => 'inverse',
        'likely pathogenic'      => 'warning',
        'pathogenic'             => 'danger',
    );
    return
      exists $color{$str}
      ? qq(<span class="btn btn-$color{$str} disabled">$str</span>)
      : $str;
}

sub parse_molecular_effects {
    my ($str) = @_;
    my %color = (
        'synonymous'  => 'success',
        'missense'    => 'inverse',
        'upstream'    => 'warning',
        'downstream'  => 'warning',
        'non_coding'  => 'warning',
        '5_prime_UTR' => 'warning',
        '3_prime_UTR' => 'warning',
        'intron'      => 'warning',
        'frameshift'  => 'warning',
        'stop_gained' => 'error',
        'nonsense'    => 'error',
    );

    my $match;
    for my $key ( keys %color ) {
        if ( $str =~ m/^$key/ ) {
            $match = $key;
            last;
        }
    }
    return ($match)
      ? qq(<span class="text-$color{$match}">$str</span>)
      : $str;
}

sub parse_annotation_impact {
    my ($str) = @_;
    my %color = (
        'LOW'      => 'success',
        'MODERATE' => 'inverse',
        'MODIFIER' => 'warning',
        'HIGH'     => 'error',
    );

    # Just default to text styling
    return qq(<span class="text-$color{$str}">$str</span>);
}

sub parse_biosample_id {
    my ($data)       = @_;
    my $biosample_id = $data->{biosampleId};
    my $zygosity     = $data->{zygosity}{label};
    my $depth        = $data->{DP};
    return $depth
      ? "$biosample_id($zygosity:$depth)"
      : "$biosample_id($zygosity)";
}

__END__

=head1 NAME

bff2json - A script that parses BFF files and serializes them to json/hash data structures.

=head1 SYNOPSIS

  bff2json.pl -i <file.bff> [-arguments|-options]

  Arguments:
    -i|--input   BFF file
    -f|--format  Output format [json|hash|json4html]

  Options:
    -h|--help        Brief help message
    --man            Full documentation
    --debug <level>  Print debugging (1..5)
    --verbose        Verbose
    -v|--version     Print version

=head1 DESCRIPTION

The script reads .bff files (JSON lines) and serializes each line to the specified format:
- hash      => uses Data::Dumper
- json      => prints NDJSON (one JSON object per line)
- json4html => aggregates the lines as a single JSON array suitable for jQuery DataTables

=head1 AUTHOR

Written by Manuel Rueda, PhD <manuel.rueda@cnag.eu>.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the terms of the
GNU General Public License as published by the Free Software Foundation; either version 3 of
the License, or (at your option) any later version.
