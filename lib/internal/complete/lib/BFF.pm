package BFF;

use strict;
use warnings;
use autodie;
use feature qw(say);
use base 'Exporter';
use vars qw(@EXPORT_OK %EXPORT_TAGS);
use Path::Tiny;
use JSON::XS;
use List::MoreUtils qw(any);
use Data::Dumper;
use BFF::Data qw(%ensglossary);
use Data::Structure::Util qw/unbless/;
$Data::Dumper::Sortkeys = 1;

sub new {
    my ( $class, $self ) = @_;
    bless $self, $class;
    return $self;
}

sub data2hash {
    my $self = shift;
    # Return the dumped structure as a string instead of printing it.
    return Dumper(unbless $self);
}

sub data2json {
    my $self = shift;
    # Return the encoded JSON as a string.
    return encode_json(unbless $self);
}

sub data2bff {
    my ( $self, $uid, $verbose ) = @_;
    my $data_mapped = mapping2beacon( $self, $uid, $verbose );
    my $coder = JSON::XS->new;
    # Return the BFF-formatted string.
    return $coder->encode($data_mapped);
}

sub mapping2beacon {
    my ( $self, $uid, $verbose ) = @_;

    # Create a few "handles" / "cursors"
    my $cursor_uid  = $self->{$uid};
    my $cursor_info = $cursor_uid->{INFO};
    my $cursor_ann  = exists $cursor_info->{ANN} ? $cursor_info->{ANN} : undef;
    my $cursor_internal  = $cursor_info->{INTERNAL};

    ####################################
    # START MAPPING TO BEACON V2 TERMS #
    ####################################

    # NB1: In general, we'll only load terms that exist
    # NB2: We deliberately create some hashes INSIDE the method <mapping2beacon>
    #      We lose a few seconds overall (tested), but it's more convenient for coding

    my $genomic_variations = {};

    # =====
    # _info => INTERNAL FIELD (not in the schema)
    # =====
    $genomic_variations->{_info} = $cursor_internal->{INFO};

    # ==============
    # alternateBases # DEPRECATED - SINCE APR-2022 !!!
    # ==============
    #$genomic_variations->{alternateBases} = $cursor_uid->{ALT};

    # =============
    # caseLevelData
    # =============
    $genomic_variations->{caseLevelData} = _map_case_level_data($cursor_internal);

    # ======================
    # frequencyInPopulations
    # ======================
    my $freq = _map_frequency($cursor_info, $cursor_internal);
    $genomic_variations->{frequencyInPopulations} = $freq if scalar(@$freq);

    # ===========
    # identifiers
    # ===========
    $genomic_variations->{identifiers} =
      _map_identifiers( $cursor_uid, $cursor_info );

    # ===================
    # molecularAttributes
    # ===================
    if ( defined $cursor_ann ) {
        $genomic_variations->{molecularAttributes} =
          _map_molecular_attributes( $cursor_ann, $cursor_uid );
    }

    # ======== *****************************************************************
    # position * WARNING!!!! DEPRECATED - USING VRS-location SINCE APR-2022 !!!*
    # ======== *****************************************************************
    $genomic_variations->{_position} = _map_position($cursor_internal);

    # =================
    # variantInternalId
    # =================
    $genomic_variations->{variantInternalId} = $uid;

    # ================
    # variantLevelData
    # ================
    my $variantLevelData = _map_variant_level_data( $cursor_info, $cursor_internal );
    $genomic_variations->{variantLevelData} = $variantLevelData
      if %$variantLevelData;

    # =========
    # variation
    # =========
    $genomic_variations->{variation} =
      _map_variation( $cursor_uid, $cursor_info, $cursor_internal,
        $genomic_variations->{identifiers} );

    ####################################
    # AD HOC TERMS (ONLY USED IN B2RI) #
    ####################################

    # ================
    # QUAL and FILTER
    # ================
    $genomic_variations->{variantQuality} = _map_variant_quality($cursor_uid);

    ##################################
    # END MAPPING TO BEACON V2 TERMS #
    ##################################

    return $genomic_variations;
}

#----------------------------------------------------------------------
# Helper: Map case-level data
#----------------------------------------------------------------------
sub _map_case_level_data {
    my ($cursor_internal) = @_;
    my $case_level_data = [];

    my %zygosity = (
        '0/1' => 'GENO_0000458',
        '0|1' => 'GENO_0000458',
        '1/0' => 'GENO_0000458',
        '1|0' => 'GENO_0000458',
        '1/1' => 'GENO_0000136',
        '1|1' => 'GENO_0000136'
    );

    for my $sample ( @{ $cursor_internal->{SAMPLES_ALT} } ) {    # $sample is hash ref
        my $tmp_ref;
        ( $tmp_ref->{biosampleId} ) = keys %{$sample};      # forcing array assignment

        # ***** zygosity
        my $tmp_sample_gt = $sample->{ $tmp_ref->{biosampleId} }{GT};
        if ($tmp_sample_gt) {
            my $tmp_zyg =
              exists $zygosity{$tmp_sample_gt}
              ? $zygosity{$tmp_sample_gt}
              : 'GENO:00000';
            $tmp_ref->{zygosity} = {
                id    => "GENO:$tmp_zyg",
                label => $tmp_sample_gt
            };
        }

        # ***** INTERNAL FIELD -> DP
        $tmp_ref->{depth} = $sample->{ $tmp_ref->{biosampleId} }{DP}
          if exists $sample->{ $tmp_ref->{biosampleId} }{DP};

        # Final Push
        push @{$case_level_data}, $tmp_ref if $tmp_ref;
    }
    return $case_level_data;
}

#----------------------------------------------------------------------
# Helper: Map frequency in populations
#----------------------------------------------------------------------
sub _map_frequency {
    my ($cursor_info, $cursor_internal) = @_;
    my $dbNSFP_version = $cursor_internal->{ANNOTATED_WITH}{toolReferences}{databases}{dbNSFP}{version};
    my @frequency_in_populations;
    my $source_freq = {
        source => {
            dbNSFP_gnomAD_exomes => 'The Genome Aggregation Database (gnomAD)',
            dbNSFP_1000Gp3       => 'The 1000 Genomes Project Phase 3',
            dbNSFP_ExAC          => 'The Exome Aggregation Consortium (ExAC)'
        },
        source_ref => {
            dbNSFP_gnomAD_exomes => 'https://gnomad.broadinstitute.org',
            dbNSFP_1000Gp3       => 'https://www.internationalgenome.org',
            dbNSFP_ExAC          => 'https://gnomad.broadinstitute.org'
        },
        version => {
            dbNSFP_gnomAD_exomes => 'Extracted from ' . $dbNSFP_version,
            dbNSFP_1000Gp3       => 'Extracted from ' . $dbNSFP_version,
            dbNSFP_ExAC          => 'Extracted from ' . $dbNSFP_version
        }
    };

    # We sort keys to allow for integration tests later
    for my $db ( sort keys %{ $source_freq->{source} } ) {
        my $tmp_pop = [];    # Must be initialized to push allele frequencies
        for my $pop (qw(AFR AMR EAS FIN NFE SAS)) {
            my $str_pop = $db . '_' . $pop . '_AF';    # e.g., dbNSFP_1000Gp3_AFR_AF

            # For whatever reason freq values are duplicated in some pops (to do: we should check if they're ALWAYS equal)
            if ( $cursor_info->{$str_pop} ) {
                my $allele_freq =
                  $cursor_info->{$str_pop} =~ m/,/
                  ? ( split /,/, $cursor_info->{$str_pop} )[0]
                  : $cursor_info->{$str_pop};
                push @{$tmp_pop},
                  {
                    population      => $pop,
                    alleleFrequency => 0 + $allele_freq
                  };
            }
        }

        # Push to frequencyInPopulations (if we had any alleleFrequency)
        push @frequency_in_populations,
          {
            frequencies     => $tmp_pop,
            source          => $source_freq->{source}{$db},
            sourceReference => $source_freq->{source_ref}{$db},
            version         => $source_freq->{version}{$db},
          }
          if scalar @$tmp_pop;
    }
    return \@frequency_in_populations;
}

#----------------------------------------------------------------------
# Helper: Map identifiers
#----------------------------------------------------------------------
sub _map_identifiers {
    my ( $cursor_uid, $cursor_info ) = @_;
    my $identifiers = {};

    # **** genomicHGVSId: This is an important field, we need it regardless of having dbNSFP_clinvar_hgvs/dbNSFP_Ensembl_geneid
    if ( exists $cursor_info->{dbNSFP_clinvar_hgvs} ) {
        $identifiers->{genomicHGVSId} = $cursor_info->{dbNSFP_clinvar_hgvs};
    }
    elsif ( exists $cursor_info->{CLINVAR_CLNHGVS} ) {
        $identifiers->{genomicHGVSId} = $cursor_info->{CLINVAR_CLNHGVS};
    }
    else {
        my $tmp_str = ':g.'
          . $cursor_uid->{POS}
          . $cursor_uid->{REF} . '>'
          . $cursor_uid->{ALT};
        my $geneid;
        $geneid = ( split /,/, $cursor_info->{dbNSFP_Ensembl_geneid} )[0]
          if $cursor_info->{dbNSFP_Ensembl_geneid};
        $identifiers->{genomicHGVSId} =
          $geneid ? $geneid . $tmp_str : $cursor_uid->{CHROM} . $tmp_str;
    }

    # **** clinvarVariantId from variant alternative ids
    my %map_variant_alternative_ids = (
        ClinVar => 'dbNSFP_clinvar_id',
        dbSNP   => 'dbNSFP_rs_dbSNP151'
    );
    while ( my ( $key, $val ) = each %map_variant_alternative_ids ) {
        next unless $key eq 'ClinVar';
        $identifiers->{clinvarVariantId} = lc($key) . ":$cursor_info->{$val}"
          if $cursor_info->{$val};
    }

    # **** Additional identifier arrays
    my %map_identifiers_array = (
        proteinHGVSIds      => 'dbNSFP_HGVSp_snpEff',
        transcriptHGVSIds   => 'dbNSFP_HGVSc_snpEff',
        dbNSFP_HGVSp_snpEff => 'dbNSFP_Ensembl_proteinid',
        dbNSFP_HGVSc_snpEff => 'dbNSFP_Ensembl_transcriptid'
    );
    while ( my ( $key, $val ) = each %map_identifiers_array ) {

        # ABOUT HGVS NOMENCLATURE: recommends Ensembl or RefSeq identifiers
        next if $key eq 'dbNSFP_HGVSp_snpEff' || $key eq 'dbNSFP_HGVSc_snpEff';
        if ( $key eq 'proteinHGVSIds' || $key eq 'transcriptHGVSIds' ) {
            my @ids =
              $cursor_info->{$val} ? split( /,/, $cursor_info->{$val} ) : ();
            my $ensembl_key =
              $map_identifiers_array{ $map_identifiers_array{$key} };
            my @ens =
              exists $cursor_info->{$ensembl_key}
              ? split( /,/, $cursor_info->{$ensembl_key} )
              : ();
            $identifiers->{$key} =
              [ map { "$ens[$_]:$ids[$_]" } ( 0 .. $#ens ) ]
              if ( @ens && ( @ens == @ids ) );
        }
        else {
            $identifiers->{$key} = [ split /,/, $cursor_info->{$val} ]
              if $cursor_info->{$val};
        }
    }

    # **** variantAlternativeIds details
    my $variantAlternativeIds = {
        ClinVar => {
            notes     => 'ClinVar Variation ID',
            reference => 'https://www.ncbi.nlm.nih.gov/clinvar/variation/'
        },
        dbSNP => {
            notes     => 'dbSNP id',
            reference => 'https://www.ncbi.nlm.nih.gov/snp/'
        }
    };
    while ( my ( $key, $val ) = each %map_variant_alternative_ids ) {
        push @{ $identifiers->{variantAlternativeIds} },
          {
            id        => "$key:$cursor_info->{$val}",
            notes     => $variantAlternativeIds->{$key}{notes},
            reference => $variantAlternativeIds->{$key}{reference}
              . $cursor_info->{$val}
          }
          if $cursor_info->{$val};
    }
    return $identifiers;
}

#----------------------------------------------------------------------
# Helper: Map molecular attributes
#----------------------------------------------------------------------
sub _map_molecular_attributes {
    my ( $cursor_ann, $cursor_uid ) = @_;
    my %molecular_atributes;
    my @fields = qw(Gene_Name Annotation HGVS.p Annotation_Impact);

    # Loop through the annotation data associated with the ALT allele
    for my $i ( 0 .. $#{ $cursor_ann->{ $cursor_uid->{ALT} } } ) {
        for my $field (@fields) {
            push @{ $molecular_atributes{$field} },
              $cursor_ann->{ $cursor_uid->{ALT} }[$i]{$field};
        }
    }
    my $molecularAttributes = {};

    $molecularAttributes->{geneIds} = $molecular_atributes{Gene_Name}
      if @{ $molecular_atributes{Gene_Name} };

    # ***** aminoacidChanges: remove prefix "p." from each value
    if ( $molecular_atributes{'HGVS.p'} && @{ $molecular_atributes{'HGVS.p'} } )
    {
        $molecularAttributes->{aminoacidChanges} =
          [ map { my $aa = $_; $aa =~ s/^p\.//; $aa }
              @{ $molecular_atributes{'HGVS.p'} } ];
    }

    # check this file ensembl-glossary.obo
    if ( $molecular_atributes{Annotation}
        && @{ $molecular_atributes{Annotation} } )
    {
        $molecularAttributes->{molecularEffects} =
          [ map { { id => map_molecular_effects_id($_), label => $_ } }
              @{ $molecular_atributes{Annotation} } ];
    }

    # INTERNAL FIELD -> annotationImpact
    $molecularAttributes->{annotationImpact} =
      $molecular_atributes{Annotation_Impact}
      if @{ $molecular_atributes{Annotation_Impact} };

    return $molecularAttributes;
}

#----------------------------------------------------------------------
# Helper: Map position information
#----------------------------------------------------------------------
sub _map_position {
    my ($cursor_internal) = @_;
    my $position = {};

    $position->{assemblyId} = $cursor_internal->{INFO}{genome};                 # 'GRCh37.p1'
    $position->{start}      = [ 0 + $cursor_internal->{POS_ZERO_BASED} ];       # coercing to number
    $position->{end}        = [ 0 + $cursor_internal->{ENDPOS_ZERO_BASED} ];    # idem

    # Ad hoc fix to speed up MongoDB positional queries (otherwise start/end are arrays)
    $position->{startInteger} = 0 + $cursor_internal->{POS_ZERO_BASED};
    $position->{endInteger}   = 0 + $cursor_internal->{ENDPOS_ZERO_BASED};

    $position->{refseqId} = "$cursor_internal->{REFSEQ}";
    return $position;
}

#----------------------------------------------------------------------
# Helper: Map variant level data (clinical interpretations)
#----------------------------------------------------------------------
sub _map_variant_level_data {
    my ( $cursor_info, $cursor_internal ) = @_;
    my $variantLevelData = {};

    my %map_variant_level_data = (
        clinicalDb         => 'CLINVAR_CLNDISDB',      # INTERNAL FIELD
        clinicalRelevance  => 'CLINVAR_CLNSIG',
        clinicalRelevances => 'CLINVAR_CLNSIGINCL',    # INTERNAL FIELD
        conditionId        => 'CLINVAR_CLNDN'
    );

    # clinicalRelevance enum values
    my @acmg_values = (
        'benign',
        'likely benign',
        'uncertain significance',
        'likely pathogenic',
        'pathogenic'
    );

    # Examples of ClinVar Annotations for CLNDISDB and CLNDN
    if (   exists $cursor_info->{ $map_variant_level_data{clinicalDb} }
        && exists $cursor_info->{ $map_variant_level_data{conditionId} } )
    {
        my @clndn = split /\|/,
          $cursor_info->{ $map_variant_level_data{conditionId} };
        my @clndisdb = split /\|/,
          $cursor_info->{ $map_variant_level_data{clinicalDb} };
        my %clinvar_ont;
        @clinvar_ont{@clndn} = @clndisdb;

        while ( my ( $key, $val ) = each %clinvar_ont ) {

            # "variantInternalId": "chr22_51064416_T_C",
            # "variantLevelData": { "clinicalInterpretations": [ { "category": { "label": "disease or disorder", "id": "MONDO:0000001" },
            # "effect": { "id": ".", "label": "ARYLSULFATASE_A_POLYMORPHISM" }, "conditionId": "ARYLSULFATASE_A_POLYMORPHISM" }
            next if $val eq '.';
            my $tmp_ref = {};
            $tmp_ref->{conditionId} = $key;
            $tmp_ref->{category} =
              { id => "MONDO:0000001", label => "disease or disorder" };

            # ***** clinicalInterpretations.effect: appears as id in ClinVar ARYLSULFATASE_A_POLYMORPHISM
            $tmp_ref->{effect} = { id => $val, label => $key };

            # ***** clinicalInterpretations.clinicalRelevance
            if (
                exists
                $cursor_info->{ $map_variant_level_data{clinicalRelevances} } )
            {
                my $tmp_var =
                  $cursor_info->{ $map_variant_level_data{clinicalRelevances} };
                warn
"CLINVAR_CLNSIGINCL is getting a value of '.' \nDid you use SnpSift annotate wth the flag -a?"
                  if $tmp_var eq '.';
                my %clnsigincl = split /[\|:]/, $tmp_var;
                my %clinvar_sig;
                @clinvar_sig{@clndn} = values %clnsigincl;    # Assuming keys match @clndn
                if ( $clinvar_sig{$key} ) {
                    my $parsed_acmg = parse_acmg_val( $clinvar_sig{$key} );
                    $tmp_ref->{clinicalRelevance} = $parsed_acmg
                      if grep { $_ eq $parsed_acmg } @acmg_values;
                }
            }
            else {
                if (
                    exists $cursor_info->{
                        $map_variant_level_data{clinicalRelevance}
                    }
                  )
                {
                    my $tmp_var =
                      $cursor_info->{ $map_variant_level_data{clinicalRelevance}
                      };
                    my $parsed_acmg = parse_acmg_val($tmp_var);
                    $tmp_ref->{clinicalRelevance} = $parsed_acmg
                      if grep { $_ eq $parsed_acmg } @acmg_values;
                }
            }

            # ***** clinicalInterpretations.annotatedeWith
            $tmp_ref->{annotatedWith} = $cursor_internal->{ANNOTATED_WITH};

            # Finally we load the data
            push @{ $variantLevelData->{clinicalInterpretations} }, $tmp_ref;
        }
    }
    return $variantLevelData;
}

#----------------------------------------------------------------------
# Helper: Map variation details
#----------------------------------------------------------------------
sub _map_variation {
    my ( $cursor_uid, $cursor_info, $cursor_internal, $identifiers ) = @_;
    my $variation = {
        referenceBases => $cursor_uid->{REF},
        alternateBases => $cursor_uid->{ALT},
        variantType    => $cursor_info->{VT},
        location       => {
            sequence_id => "HGVSid:$identifiers->{genomicHGVSId}",    # We leverage the previous parsing
            type        => 'SequenceLocation',
            interval    => {
                type  => 'SequenceInterval',
                start => {
                    type  => 'Number',
                    value => 0 + $cursor_internal->{POS_ZERO_BASED}
                },
                end => {
                    type  => 'Number',
                    value => 0 + $cursor_internal->{ENDPOS_ZERO_BASED}
                }
            }
        }
    };
    return $variation;
}

#----------------------------------------------------------------------
# Helper: Map variant quality (QUAL and FILTER)
#----------------------------------------------------------------------
sub _map_variant_quality {
    my ($cursor_uid) = @_;
    my %quality;
    for my $term (qw(QUAL FILTER)) {
        $quality{$term} =
          $term eq 'QUAL' ? 0 + $cursor_uid->{$term} : $cursor_uid->{$term};
    }
    return \%quality;
}

sub parse_acmg_val {

    # Only accepting the possibilities enumerated in Beacon v2 Models
    # In reality the scenarios are far more complex

    # CINEKA UK1 - chr22:
    #
    #   3885 Benign
    #   1673 Likely_benign
    #    777 Uncertain_significance
    #    399 Benign/Likely_benign
    #    317 Conflicting_interpretations_of_pathogenicity
    #     54 drug_response
    #     24
    #     11 not_provided
    #      9 Pathogenic/Likely_pathogenic
    #      9 Pathogenic
    #      9 Likely_pathogenic
    #      6 risk_factor
    #      6 Likely_benign,_other
    #      4 Likely_benign,_drug_response,_other
    #      2 Conflicting_interpretations_of_pathogenicity,_risk_factor
    #      2 Benign,_risk_factor
    #      1 Uncertain_significance,_risk_factor
    #      1 drug_response,_risk_factor
    #      1 Benign,_other
    #      1 Benign/Likely_benign,_risk_factor
    #      1 Benign/Likely_benign,_other

    my $val = shift;

    # Pathogenic/Likely_pathogenic => keeping first value until Models accept multiple values
    $val = $val =~ m#(\w+)/# ? $1 : $val;
    $val = lc($val);
    $val =~ tr/_/ /;
    return $val;
}

sub map_molecular_effects_id {

    # CINEKA UK1 - chr22:
    #
    #  533041 intron_variant
    #  345952 intergenic_region
    #   97738 upstream_gene_variant
    #   75090 downstream_gene_variant
    #   22552 3_prime_UTR_variant
    #   13353 missense_variant
    #    9274 synonymous_variant
    #    4793 non_coding_transcript_exon_variant
    #    3467 5_prime_UTR_variant
    #    1743 splice_region_variant&intron_variant
    #     818 5_prime_UTR_premature_start_codon_gain_variant
    #     344 missense_variant&splice_region_variant
    #     271 stop_gained
    #     218 splice_region_variant&synonymous_variant
    #     137 splice_region_variant&non_coding_transcript_exon_variant
    #     134 splice_donor_variant&intron_variant
    #     116 splice_region_variant
    #     110 splice_acceptor_variant&intron_variant
    #      67 frameshift_variant
    #      39 start_lost
    #      38 disruptive_inframe_deletion
    #      15 conservative_inframe_deletion
    #      14 stop_lost
    #      10 conservative_inframe_insertion
    #       8 disruptive_inframe_insertion
    #       6 stop_gained&splice_region_variant
    #       4 stop_retained_variant
    #       4 splice_acceptor_variant&splice_region_variant&intron_variant
    #       3 splice_acceptor_variant&splice_donor_variant&intron_variant
    #       2 initiator_codon_variant
    #       1 splice_donor_variant&splice_region_variant&intron_variant&non_coding_transcript_exon_variant
    #       1 splice_acceptor_variant&splice_region_variant&intron_variant&non_coding_transcript_exon_variant
    #       1 splice_acceptor_variant&splice_region_variant&5_prime_UTR_variant&intron_variant
    #       1 frameshift_variant&stop_lost
    #       1 frameshift_variant&start_lost
    #       1 frameshift_variant&splice_region_variant
    #       1 conservative_inframe_deletion&splice_region_variant
    #       1 bidirectional_gene_fusion

    my $val     = shift;
    my $default = 'ENSGLOSSARY:0000000';

    # Until further notice we check ONLY the first value before the ampersand (&)
    if ( $val =~ m/\&/ ) {
        $val =~ m/^(\w+)\&/;
        $val = $1;
    }

    # Ad hoc solution for catching $val='intergenic_region'
    $val = 'Intergenic_variant' if $val eq 'intergenic_region';
    return exists $ensglossary{ ucfirst($val) }
      ? $ensglossary{ ucfirst($val) }
      : $default;
}
1;
