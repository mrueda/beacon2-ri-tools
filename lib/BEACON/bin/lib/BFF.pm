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

#use Storable qw(dclone); # To clone complex references
use Data::Structure::Util qw/unbless/;
$Data::Dumper::Sortkeys = 1;

sub new {
    my ( $class, $self ) = @_;
    bless $self, $class;
    return $self;
}

sub data2hash {
    my $self = shift;
    print Dumper ( unbless $self);    # To avoid using {$uid => {$self->{$uid}}
}

sub data2json {
    my $self = shift;
    say encode_json( unbless $self);    # No order
}

sub data2bff {
    my ( $self, $uid, $verbose ) = @_;
    my $data_mapped = mapping2beacon( $self, $uid, $verbose );

    my $coder = JSON::XS->new;
    return $coder->encode($data_mapped);    # No order
}

sub mapping2beacon {
    my ( $self, $uid, $verbose ) = @_;

    # Create a few "handles" / "cursors"
    my $cursor_uid  = $self->{$uid};
    my $cursor_info = $cursor_uid->{INFO};
    my $cursor_ann  = exists $cursor_info->{ANN} ? $cursor_info->{ANN} : undef;
    my $cursor_crg  = $cursor_info->{CRG};

    ####################################
    # START MAPPING TO BEACON V2 TERMS #
    ####################################

    # NB1: In general, we'll only load terms that exist
    # NB2: We deliberately create some hashes INSIDE the method <mapping2beacon>
    #      We lose a few seconds overall (tested), but it's more convenient for coding

    my $genomic_variations;

    # =====
    # _info => INTERNAL FIELD (not in the schema)
    # =====
    $genomic_variations->{_info} = $cursor_crg->{INFO};

    # ==============
    # alternateBases # DEPRECATED - SINCE APR-2022 !!!
    # ==============

    #$genomic_variations->{alternateBases} = $cursor_uid->{ALT};

    # =============
    # caseLevelData
    # =============

    $genomic_variations->{caseLevelData} = [];    # array ref

    my %zygosity = (
        '0/1' => 'GENO_0000458',
        '0|1' => 'GENO_0000458',
        '1/0' => 'GENO_0000458',
        '1|0' => 'GENO_0000458',
        '1/1' => 'GENO_0000136',
        '1|1' => 'GENO_0000136'
    );

    for my $sample ( @{ $cursor_crg->{SAMPLES_ALT} } ) {    #$sample is hash ref
        my $tmp_ref;
        ( $tmp_ref->{biosampleId} ) = keys %{$sample};      # forcing array assignment
                                                            # ($tmp_ref->{individualId}) = keys %{ $sample}; # forcing array assignment

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

        # ***** phenotypicEffects

        # Final Push
        push @{ $genomic_variations->{caseLevelData} }, $tmp_ref if $tmp_ref;
    }

    # ======================
    # frequencyInPopulations
    # ======================

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
            dbNSFP_gnomAD_exomes => 'Extracted from dbNSFP4.1a',
            dbNSFP_1000Gp3       => 'Extracted from dbNSFP4.1a',
            dbNSFP_ExAC          => 'Extracted from dbNSFP4.1a'
        }
    };

    # We sort keys to allow for integration tests later
    for my $db ( sort keys %{ $source_freq->{source} } ) {

        # First we create an array for each population (if present)
        my $tmp_pop = [];    # Must be initialized in order to push @{$tmp_pop}
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

        # Secondly we push to the array <frequencyInPopulations> (if we had any alleleFrequency)
        push @{ $genomic_variations->{frequencyInPopulations} },
          {
            frequencies     => $tmp_pop,
            source          => $source_freq->{source}{$db},
            sourceReference => $source_freq->{source_ref}{$db},
            version         => $source_freq->{version}{$db},
          }
          if scalar @$tmp_pop;
    }

    # ===========
    # identifiers
    # ===========

    my %map_identifiers_uniq = ( genomicHGVSId => 'dbNSFP_clinvar_hgvs' );

    my %map_identifiers_array = (

        # clinVarIds          => 'dbNSFP_clinvar_id', # DEPRECATED - SINCE APR-2022 !!!
        proteinHGVSIds      => 'dbNSFP_HGVSp_snpEff',
        transcriptHGVSIds   => 'dbNSFP_HGVSc_snpEff',
        dbNSFP_HGVSp_snpEff => 'dbNSFP_Ensembl_proteinid',
        dbNSFP_HGVSc_snpEff => 'dbNSFP_Ensembl_transcriptid'
    );

    my %map_variant_alternative_ids = (
        ClinVar => 'dbNSFP_clinvar_id',
        dbSNP   => 'dbNSFP_rs_dbSNP151'
    );

    # **** clinvarVariantId
    while ( my ( $key, $val ) = each %map_variant_alternative_ids ) {
        next unless $key eq 'ClinVar';
        $genomic_variations->{identifiers}{clinvarVariantId} =
          lc($key) . ":$cursor_info->{$val}"
          if $cursor_info->{$val};
    }

    # **** genomicHGVSId

    # This is an important field, we need it regardless of having dbNSFP_clinvar_hgvs/dbNSFP_Ensembl_geneid
    if ( exists $cursor_info->{dbNSFP_clinvar_hgvs} ) {
        $genomic_variations->{identifiers}{genomicHGVSId} =
          $cursor_info->{dbNSFP_clinvar_hgvs};
    }
    elsif ( exists $cursor_info->{CLINVAR_CLNHGVS} ) {
        $genomic_variations->{identifiers}{genomicHGVSId} =
          $cursor_info->{CLINVAR_CLNHGVS};
    }
    else {
        my $tmp_str = ':g.'
          . $cursor_uid->{POS}
          . $cursor_uid->{REF} . '>'
          . $cursor_uid->{ALT};

        # dbNSFP_Ensembl_geneid	ENSG00000186092,ENSG00000186092 (duplicated)
        my $geneid;
        $geneid = ( split /,/, $cursor_info->{dbNSFP_Ensembl_geneid} )[0]
          if $cursor_info->{dbNSFP_Ensembl_geneid};
        $genomic_variations->{identifiers}{genomicHGVSId} =
          $geneid ? $geneid . $tmp_str : $cursor_uid->{CHROM} . $tmp_str;
    }

    while ( my ( $key, $val ) = each %map_identifiers_array ) {

        # ABOUT HGVS NOMENCLATURE recommends Ensembl or RefSeq
        # https://genome.ucsc.edu/FAQ/FAQgenes.html#ens
        # Ensembl (GENCODE): ENSG*, ENSP*, ENST*
        # RefSeq : NM_*, NP_*

        # genomicHGVSId => dbNSFP_clinvar_hgvs (USED)
        # transcriptHGVSId => dbNSFP_Ensembl_transcriptid (USED), ANN:Feature_ID
        # proteinHGVSIds  => dbNSFP_Ensembl_proteinid (USED)
        #For HGVS.p we don't have NP_ ids in ANN but we have ENS in dbNSFP_Ensembl_proteinid anyway until we solve the issue
        next
          if ( $key eq 'dbNSFP_HGVSp_snpEff'
            || $key eq 'dbNSFP_HGVSc_snpEff' );
        if ( $key eq 'proteinHGVSIds' || $key eq 'transcriptHGVSIds' ) {
            my ( @ids, @ens );
            @ids = split /,/, $cursor_info->{$val} if $cursor_info->{$val};
            @ens = split /,/,
              $cursor_info
              ->{ $map_identifiers_array{ $map_identifiers_array{$key} } }
              if exists $cursor_info
              ->{ $map_identifiers_array{ $map_identifiers_array{$key} } };
            $genomic_variations->{identifiers}{$key} =
              [ map { "$ens[$_]:$ids[$_]" } ( 0 .. $#ens ) ]
              if ( @ens && ( @ens == @ids ) );
        }
        else {
            $genomic_variations->{identifiers}{$key} =
              [ split /,/, $cursor_info->{$val} ]
              if $cursor_info->{$val};

        }
    }

    # ***** variantAlternativeIds
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
        push @{ $genomic_variations->{identifiers}{variantAlternativeIds} },
          {
            id        => "$key:$cursor_info->{$val}",
            notes     => $variantAlternativeIds->{$key}{notes},
            reference => $variantAlternativeIds->{$key}{reference}
              . $cursor_info->{$val}
          }
          if $cursor_info->{$val};
    }

    # ===================
    # molecularAttributes
    # ===================

    # We have cDNA info in multiple fields but for consistency we extract it from ANN
    if ( defined $cursor_ann ) {
        my @molecular_atributes =
          qw(Gene_Name Annotation HGVS.p Annotation_Impact);
        my $molecular_atribute = {};
        for my $i ( 0 .. $#{ $cursor_ann->{ $cursor_uid->{ALT} } } ) {
            for my $ma (@molecular_atributes) {
                push @{ $molecular_atribute->{$ma} },
                  $cursor_ann->{ $cursor_uid->{ALT} }[$i]{$ma};
            }
        }
        $genomic_variations->{molecularAttributes}{geneIds} =
          $molecular_atribute->{Gene_Name}
          if @{ $molecular_atribute->{Gene_Name} };
        $genomic_variations->{molecularAttributes}{aminoacidChanges} =
          [ map { s/^p\.//; $_ } @{ $molecular_atribute->{'HGVS.p'} } ]
          if scalar @{ $molecular_atribute->{'HGVS.p'} };

        # check this file ensembl-glossary.obo
        $genomic_variations->{molecularAttributes}{molecularEffects} =
          [ map { { id => map_molecular_effects_id($_), label => $_ } }
              @{ $molecular_atribute->{Annotation} } ]
          if scalar @{ $molecular_atribute->{Annotation} };

        # INTERNAL FIELD -> annotationImpact
        $genomic_variations->{molecularAttributes}{annotationImpact} =
          $molecular_atribute->{Annotation_Impact}
          if scalar @{ $molecular_atribute->{Annotation_Impact} };

    }

    # ======== *****************************************************************
    # position * WARNING!!!! DEPRECATED - USING VRS-location SINCE APR-2022 !!!*
    # ======== *****************************************************************

    my $position_str = '_position';

    $genomic_variations->{$position_str}{assemblyId} =
      $cursor_crg->{INFO}{genome};    #'GRCh37.p1'
    $genomic_variations->{$position_str}{start} =
      [ 0 + $cursor_crg->{POS_ZERO_BASED} ];    # coercing to number (split values are strings to Perl)
    $genomic_variations->{$position_str}{end} =
      [ 0 + $cursor_crg->{ENDPOS_ZERO_BASED} ];    # idem

    # ************************************************************************
    # Ad hoc fix to speed up MongoDB positional queries (otherwise start/end are arrays)
    $genomic_variations->{$position_str}{startInteger} =
      0 + $cursor_crg->{POS_ZERO_BASED};
    $genomic_variations->{$position_str}{endInteger} =
      0 + $cursor_crg->{ENDPOS_ZERO_BASED};

    # ************************************************************************

    $genomic_variations->{$position_str}{refseqId} = "$cursor_crg->{REFSEQ}";

    # ==============
    # referenceBases # DEPRECATED - SINCE APR-2022 !!!
    # ==============

    #$genomic_variations->{referenceBases} = $cursor_uid->{REF};

    # =================
    # variantInternalId
    # =================

    $genomic_variations->{variantInternalId} = $uid;

    # ================
    # variantLevelData
    # ================

    # NB: snpsift annotate was run w/o <-a>, thus we should not get '.' on empty fields
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
    #
    # CLNDISDB=Human_Phenotype_Ontology:HP:0000090,Human_Phenotype_Ontology:HP:0004748,MONDO:MONDO:0019005,MedGen:C0687120,OMIM:PS256100,Orphanet:ORPHA655,SNOMED_CT:204958008|MONDO:MONDO:0011752,MedGen:C1847013,OMIM:606966|MONDO:MONDO:0011756,MedGen:C1846979,OMIM:606996|MedGen:CN517202
    #
    # CLNDN=Nephronophthisis|Nephronophthisis_4|Senior-Loken_syndrome_4|not_provided

    # ***** clinicalInterpretations
    if (   exists $cursor_info->{ $map_variant_level_data{clinicalDb} }
        && exists $cursor_info->{ $map_variant_level_data{conditionId} } )
    {
        # we will use tmp arrays to parse such fields
        my @clndn = split /\|/,
          $cursor_info->{ $map_variant_level_data{conditionId} };
        my @clndisdb = split /\|/,
          $cursor_info->{ $map_variant_level_data{clinicalDb} };
        my %clinvar_ont;
        @clinvar_ont{@clndn} = @clndisdb;

        while ( my ( $key, $val ) = each %clinvar_ont ) {

            # "variantInternalId": "chr22_51064416_T_C",
            # "variantLevelData": { "clinicalInterpretations": [ { "category": { "label": "disease or disorder", "id": "MONDO:0000001" }, "effect": { "id": ".", "label": "ARYLSULFATASE_A_POLYMORPHISM" }, "conditionId": "ARYLSULFATASE_A_POLYMORPHISM" }
            next if $val eq '.';

            my $tmp_ref;
            $tmp_ref->{conditionId} = $key;
            $tmp_ref->{category} =
              { id => "MONDO:0000001", label => "disease or disorder" };

            # ***** clinicalInterpretations.effect
            # appeears as id in ClinVar ARYLSULFATASE_A_POLYMORPHISM
            $tmp_ref->{effect} = {
                id    => $val,
                label => $key
            };

            # ***** clinicalInterpretations.clinicalRelevance
            # Here we will use singular (CLINVAR_CLNSIG=Pathogenic) or plural (CLINVAR_CLNSIGINCL=816687:Pathogenic|81668o:Benign) depending on how many anootations
            if (
                exists
                $cursor_info->{ $map_variant_level_data{clinicalRelevances} } )
            {
                my $tmp_var =
                  $cursor_info->{ $map_variant_level_data{clinicalRelevances} };
                warn
"CLINVAR_CLNSIGINCL is getting a value of '.' \nDid you use SnpSift annotate wth the flag -a?"
                  if $tmp_var eq '.';
                my %clnsigincl = split /[\|:]/, $tmp_var;    # ( 816687 => Pathogenic, 816680 => 'Benign' )
                my %clinvar_sig;
                @clinvar_sig{@clndn} = values %clnsigincl;    # Assuming @cldn eq keys %clnsigincl
                                                              #print Dumper \%clinvar_sig;
                if ( $clinvar_sig{$key} ) {
                    my $parsed_acmg = parse_acmg_val( $clinvar_sig{$key} );
                    $tmp_ref->{clinicalRelevance} = $parsed_acmg
                      if any { $_ eq $parsed_acmg } @acmg_values;
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
                      if any { $_ eq $parsed_acmg } @acmg_values;
                }
            }

            # ***** clinicalInterpretations.annotatedeWith
            $tmp_ref->{annotatedWith} = $cursor_crg->{ANNOTATED_WITH};

            # Finally we load the data
            push @{ $genomic_variations->{variantLevelData}
                  {clinicalInterpretations} }, $tmp_ref;
        }
    }

    # ===========
    # variantType # DEPRECATED - SINCE APR-2022 !!!
    # ===========

    # $genomic_variations->{variantType} = $cursor_info->{VT};

    # =========
    # variation
    # =========

    my $variation_str = 'variation';

    # variation->oneOf->LegacyVariation
    # Most terms exist so we can load the hash at once!!
    $genomic_variations->{$variation_str} = {
        referenceBases => $cursor_uid->{REF},
        alternateBases => $cursor_uid->{ALT},
        variantType    => $cursor_info->{VT},
        location       => {
            sequence_id =>
              "HGVSid:$genomic_variations->{identifiers}{genomicHGVSId}",    # We leverage the previous parsing
            type     => 'SequenceLocation',
            interval => {
                type  => 'SequenceInterval',
                start => {
                    type  => 'Number',
                    value => ( 0 + $cursor_crg->{POS_ZERO_BASED} )
                },
                end => {
                    type  => 'Number',
                    value => ( 0 + $cursor_crg->{ENDPOS_ZERO_BASED} )
                }
            }
        }
    };

    ####################################
    # AD HOC TERMS (ONLY USED IN B2RI) #
    ####################################

    # ================
    # QUAL and FILTER
    # ================
    for my $term (qw(QUAL FILTER)) {

        # We're going to store under <variantQuality>
        $genomic_variations->{variantQuality}{$term} =
          $term eq 'QUAL' ? 0 + $cursor_uid->{$term} : $cursor_uid->{$term};
    }

    ##################################
    # END MAPPING TO BEACON V2 TERMS #
    ##################################

    return $genomic_variations;
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
