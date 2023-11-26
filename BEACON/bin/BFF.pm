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

#use Storable qw(dclone); # To clone complex references
use Data::Structure::Util qw/unbless/;
$Data::Dumper::Sortkeys = 1;

BEGIN {
    @EXPORT_OK   = qw(%chr_name_conv %vcf_data_loc);
    %EXPORT_TAGS = ();
}

# Harmonizing chromosomic nomenclature
# bcftools annotate --rename-chrs ./chr_name_conv.txt
our %chr_name_conv = (
    'chr1'  => 1,
    'chr2'  => 2,
    'chr3'  => 3,
    'chr4'  => 4,
    'chr5'  => 5,
    'chr6'  => 6,
    'chr7'  => 7,
    'chr8'  => 8,
    'chr9'  => 9,
    'chr10' => 10,
    'chr11' => 11,
    'chr12' => 12,
    'chr13' => 13,
    'chr14' => 14,
    'chr15' => 15,
    'chr16' => 16,
    'chr17' => 17,
    'chr18' => 18,
    'chr19' => 19,
    'chr20' => 20,
    'chr21' => 21,
    'chr22' => 22,
    'chr23' => 'X',
    '23'    => 'X',
    'chr24' => 'Y',
    '24'    => 'Y',
    'chr25' => 'XY',
    '25'    => 'XY',
    'chr26' => 'MT',
    '26'    => 'MT',
    'chrM'  => 'MT',
    'M'     => 'MT'
);

# Add standard key-values 1..22,X,Y to %chr_name_conv
@chr_name_conv{ 1 .. 22, qw[X Y] } = ( 1 .. 22, qw[X Y] );

# Defining data location in VCF columns
our %vcf_data_loc = (
    CHROM   => 0,
    POS     => 1,
    ID      => 2,
    REF     => 3,
    ALT     => 4,
    QUAL    => 5,
    FILTER  => 6,
    INFO    => 7,
    FORMAT  => 8,
    SAMPLES => 9    # Info about start column for samples
);

my %ensglossary = (
    "Genome_annotation"                    => 'ENSGLOSSARY:0000001',
    "Gene"                                 => 'ENSGLOSSARY:0000002',
    "Transcript"                           => 'ENSGLOSSARY:0000003',
    "EST"                                  => 'ENSGLOSSARY:0000004',
    "Transcript_support_level"             => 'ENSGLOSSARY:0000005',
    "TSL_1"                                => 'ENSGLOSSARY:0000006',
    "TSL_2"                                => 'ENSGLOSSARY:0000007',
    "TSL_3"                                => 'ENSGLOSSARY:0000008',
    "TSL_4"                                => 'ENSGLOSSARY:0000009',
    "TSL_5"                                => 'ENSGLOSSARY:0000010',
    "TSL_NA"                               => 'ENSGLOSSARY:0000011',
    "APPRIS"                               => 'ENSGLOSSARY:0000012',
    "APPRIS_P1"                            => 'ENSGLOSSARY:0000013',
    "APPRIS_P2"                            => 'ENSGLOSSARY:0000014',
    "APPRIS_P3"                            => 'ENSGLOSSARY:0000015',
    "APPRIS_P4"                            => 'ENSGLOSSARY:0000016',
    "APPRIS_P5"                            => 'ENSGLOSSARY:0000017',
    "APPRIS_ALT1"                          => 'ENSGLOSSARY:0000018',
    "APPRIS_ALT2"                          => 'ENSGLOSSARY:0000019',
    "GENCODE_Basic"                        => 'ENSGLOSSARY:0000020',
    "5'_incomplete"                        => 'ENSGLOSSARY:0000021',
    "3'_incomplete"                        => 'ENSGLOSSARY:0000022',
    "Ensembl_canonical"                    => 'ENSGLOSSARY:0000023',
    "CCDS"                                 => 'ENSGLOSSARY:0000024',
    "Biotype"                              => 'ENSGLOSSARY:0000025',
    "Protein_coding"                       => 'ENSGLOSSARY:0000026',
    "Processed_transcript"                 => 'ENSGLOSSARY:0000027',
    "Long_non-coding_RNA_(lncRNA)"         => 'ENSGLOSSARY:0000028',
    "Non_coding"                           => 'ENSGLOSSARY:0000029',
    "3'_overlapping_ncRNA"                 => 'ENSGLOSSARY:0000030',
    "Antisense"                            => 'ENSGLOSSARY:0000031',
    "lincRNA_(long_intergenic_ncRNA)"      => 'ENSGLOSSARY:0000032',
    "Retained_intron"                      => 'ENSGLOSSARY:0000033',
    "Sense_intronic"                       => 'ENSGLOSSARY:0000034',
    "Sense_overlapping"                    => 'ENSGLOSSARY:0000035',
    "Macro_lncRNA"                         => 'ENSGLOSSARY:0000036',
    "ncRNA"                                => 'ENSGLOSSARY:0000037',
    "miRNA"                                => 'ENSGLOSSARY:0000038',
    "piRNA"                                => 'ENSGLOSSARY:0000039',
    "rRNA"                                 => 'ENSGLOSSARY:0000040',
    "siRNA"                                => 'ENSGLOSSARY:0000041',
    "snRNA"                                => 'ENSGLOSSARY:0000042',
    "snoRNA"                               => 'ENSGLOSSARY:0000043',
    "tRNA"                                 => 'ENSGLOSSARY:0000044',
    "vaultRNA"                             => 'ENSGLOSSARY:0000045',
    "miscRNA"                              => 'ENSGLOSSARY:0000046',
    "Pseudogene"                           => 'ENSGLOSSARY:0000047',
    "Processed_pseudogene"                 => 'ENSGLOSSARY:0000048',
    "Unprocessed_pseudogene"               => 'ENSGLOSSARY:0000049',
    "Transcribed_pseudogene"               => 'ENSGLOSSARY:0000050',
    "Translated_pseudogene"                => 'ENSGLOSSARY:0000051',
    "Polymorphic_pseudogene"               => 'ENSGLOSSARY:0000052',
    "Unitary_pseudogene"                   => 'ENSGLOSSARY:0000053',
    "IG_pseudogene"                        => 'ENSGLOSSARY:0000054',
    "IG_gene"                              => 'ENSGLOSSARY:0000055',
    "TR_gene"                              => 'ENSGLOSSARY:0000056',
    "TEC_(To_be_Experimentally_Confirmed)" => 'ENSGLOSSARY:0000057',
    "Readthrough"                          => 'ENSGLOSSARY:0000058',
    "IG_V_gene"                            => 'ENSGLOSSARY:0000059',
    "IG_D_gene"                            => 'ENSGLOSSARY:0000060',
    "IG_J_gene"                            => 'ENSGLOSSARY:0000061',
    "IG_C_gene"                            => 'ENSGLOSSARY:0000062',
    "TR_V_gene"                            => 'ENSGLOSSARY:0000063',
    "TR_D_gene"                            => 'ENSGLOSSARY:0000064',
    "TR_J_gene"                            => 'ENSGLOSSARY:0000065',
    "TR_C_gene"                            => 'ENSGLOSSARY:0000066',
    "cDNA"                                 => 'ENSGLOSSARY:0000067',
    "CDS"                                  => 'ENSGLOSSARY:0000068',
    "Peptide"                              => 'ENSGLOSSARY:0000069',
    "Protein_domain"                       => 'ENSGLOSSARY:0000070',
    "Exon"                                 => 'ENSGLOSSARY:0000071',
    "Intron"                               => 'ENSGLOSSARY:0000072',
    "Codon"                                => 'ENSGLOSSARY:0000073',
    "Constitutive_exon"                    => 'ENSGLOSSARY:0000074',
    "Phase"                                => 'ENSGLOSSARY:0000075',
    "Flanking_sequence"                    => 'ENSGLOSSARY:0000076',
    "Untranslated_region"                  => 'ENSGLOSSARY:0000077',
    "5'_UTR"                               => 'ENSGLOSSARY:0000078',
    "3'_UTR"                               => 'ENSGLOSSARY:0000079',
    "Homologues"                           => 'ENSGLOSSARY:0000080',
    "Gene_tree"                            => 'ENSGLOSSARY:0000081',
    "Orthologues"                          => 'ENSGLOSSARY:0000082',
    "1-to-1_orthologues"                   => 'ENSGLOSSARY:0000083',
    "1-to-many_orthologues"                => 'ENSGLOSSARY:0000084',
    "Many-to-many_orthologues"             => 'ENSGLOSSARY:0000085',
    "Paralogues"                           => 'ENSGLOSSARY:0000086',
    "Between_species_paralogues"           => 'ENSGLOSSARY:0000087',
    "Gene_split"                           => 'ENSGLOSSARY:0000088',
    "Other_paralogues"                     => 'ENSGLOSSARY:0000089',
    "Within_species_paralogues"            => 'ENSGLOSSARY:0000090',
    "Homoeologues"                         => 'ENSGLOSSARY:0000091',
    "Variant"                              => 'ENSGLOSSARY:0000092',
    "QTL"                                  => 'ENSGLOSSARY:0000093',
    "eQTL"                                 => 'ENSGLOSSARY:0000094',
    "Evidence_status"                      => 'ENSGLOSSARY:0000095',
    "Sequence_variant"                     => 'ENSGLOSSARY:0000096',
    "Structural_variant"                   => 'ENSGLOSSARY:0000097',
    "SNP"                                  => 'ENSGLOSSARY:0000098',
    "Insertion"                            => 'ENSGLOSSARY:0000099',
    "Deletion"                             => 'ENSGLOSSARY:0000100',
    "Indel"                                => 'ENSGLOSSARY:0000101',
    "Substitution"                         => 'ENSGLOSSARY:0000102',
    "CNV"                                  => 'ENSGLOSSARY:0000103',
    "Inversion"                            => 'ENSGLOSSARY:0000104',
    "Translocation"                        => 'ENSGLOSSARY:0000105',
    "Allele_(variant)"                     => 'ENSGLOSSARY:0000106',
    "Allele_(gene)"                        => 'ENSGLOSSARY:0000107',
    "Reference_allele"                     => 'ENSGLOSSARY:0000108',
    "Alternative_allele"                   => 'ENSGLOSSARY:0000109',
    "Major_allele"                         => 'ENSGLOSSARY:0000110',
    "Minor_allele"                         => 'ENSGLOSSARY:0000111',
    "Private_allele"                       => 'ENSGLOSSARY:0000112',
    "Ancestral_allele"                     => 'ENSGLOSSARY:0000113',
    "Minor_allele_frequency"               => 'ENSGLOSSARY:0000114',
    "Highest_population_MAF"               => 'ENSGLOSSARY:0000115',
    "Global_MAF"                           => 'ENSGLOSSARY:0000116',
    "Genotype"                             => 'ENSGLOSSARY:0000117',
    "Genetic_marker"                       => 'ENSGLOSSARY:0000118',
    "Tandem_repeat"                        => 'ENSGLOSSARY:0000119',
    "Alu_insertion"                        => 'ENSGLOSSARY:0000120',
    "Complex_structural_alteration"        => 'ENSGLOSSARY:0000121',
    "Complex_substitution"                 => 'ENSGLOSSARY:0000122',
    "Interchromosomal_breakpoint"          => 'ENSGLOSSARY:0000123',
    "Interchromosomal_translocation"       => 'ENSGLOSSARY:0000124',
    "Intrachromosomal_breakpoint"          => 'ENSGLOSSARY:0000125',
    "Intrachromosomal_translocation"       => 'ENSGLOSSARY:0000126',
    "Loss_of_heterozygosity"               => 'ENSGLOSSARY:0000127',
    "Mobile_element_deletion"              => 'ENSGLOSSARY:0000128',
    "Mobile_element_insertion"             => 'ENSGLOSSARY:0000129',
    "Novel_sequence_insertion"             => 'ENSGLOSSARY:0000130',
    "Short_tandem_repeat_variant"          => 'ENSGLOSSARY:0000131',
    "Tandem_duplication"                   => 'ENSGLOSSARY:0000132',
    "Probe"                                => 'ENSGLOSSARY:0000133',
    "Variant_consequence"                  => 'ENSGLOSSARY:0000134',
    "Variant_impact"                       => 'ENSGLOSSARY:0000135',
    "High_impact_variant_consequence"      => 'ENSGLOSSARY:0000136',
    "Moderate_impact_variant_consequence"  => 'ENSGLOSSARY:0000137',
    "Low_impact_variant_consequence"       => 'ENSGLOSSARY:0000138',
    "Modifier_impact_variant_consequence"  => 'ENSGLOSSARY:0000139',
    "Transcript_ablation"                  => 'ENSGLOSSARY:0000140',
    "Splice_acceptor_variant"              => 'ENSGLOSSARY:0000141',
    "Splice_donor_variant"                 => 'ENSGLOSSARY:0000142',
    "Stop_gained"                          => 'ENSGLOSSARY:0000143',
    "Frameshift_variant"                   => 'ENSGLOSSARY:0000144',
    "Stop_lost"                            => 'ENSGLOSSARY:0000145',
    "Start_lost"                           => 'ENSGLOSSARY:0000146',
    "Transcript_amplification"             => 'ENSGLOSSARY:0000147',
    "Inframe_insertion"                    => 'ENSGLOSSARY:0000148',
    "Inframe_deletion"                     => 'ENSGLOSSARY:0000149',
    "Missense_variant"                     => 'ENSGLOSSARY:0000150',
    "Protein_altering_variant"             => 'ENSGLOSSARY:0000151',
    "Splice_region_variant"                => 'ENSGLOSSARY:0000152',
    "Incomplete_terminal_codon_variant"    => 'ENSGLOSSARY:0000153',
    "Stop_retained_variant"                => 'ENSGLOSSARY:0000154',
    "Synonymous_variant"                   => 'ENSGLOSSARY:0000155',
    "Coding_sequence_variant"              => 'ENSGLOSSARY:0000156',
    "Mature_miRNA_variant"                 => 'ENSGLOSSARY:0000157',
    "5_prime_UTR_variant"                  => 'ENSGLOSSARY:0000158',
    "3_prime_UTR_variant"                  => 'ENSGLOSSARY:0000159',
    "Non_coding_transcript_exon_variant"   => 'ENSGLOSSARY:0000160',
    "Intron_variant"                       => 'ENSGLOSSARY:0000161',
    "NMD_transcript_variant"               => 'ENSGLOSSARY:0000162',
    "Non_coding_transcript_variant"        => 'ENSGLOSSARY:0000163',
    "Upstream_gene_variant"                => 'ENSGLOSSARY:0000164',
    "Downstream_gene_variant"              => 'ENSGLOSSARY:0000165',
    "TFBS_ablation"                        => 'ENSGLOSSARY:0000166',
    "TFBS_amplification"                   => 'ENSGLOSSARY:0000167',
    "TF_binding_site_variant"              => 'ENSGLOSSARY:0000168',
    "Regulatory_region_ablation"           => 'ENSGLOSSARY:0000169',
    "Regulatory_region_amplification"      => 'ENSGLOSSARY:0000170',
    "Feature_elongation"                   => 'ENSGLOSSARY:0000171',
    "Regulatory_region_variant"            => 'ENSGLOSSARY:0000172',
    "Feature_truncation"                   => 'ENSGLOSSARY:0000173',
    "Intergenic_variant"                   => 'ENSGLOSSARY:0000174',
    "Ambiguity_code"                       => 'ENSGLOSSARY:0000175',
    "Flagged_variant"                      => 'ENSGLOSSARY:0000176',
    "Clinical_significance"                => 'ENSGLOSSARY:0000177',
    "Linkage_disequilibrium"               => 'ENSGLOSSARY:0000178',
    "r2"                                   => 'ENSGLOSSARY:0000179',
    "D'"                                   => 'ENSGLOSSARY:0000180',
    "Haplotype_(variation)"                => 'ENSGLOSSARY:0000181',
    "Transcript_haplotype"                 => 'ENSGLOSSARY:0000182',
    "Genome"                               => 'ENSGLOSSARY:0000183',
    "Genome_assembly"                      => 'ENSGLOSSARY:0000184',
    "Coverage"                             => 'ENSGLOSSARY:0000185',
    "Primary_assembly"                     => 'ENSGLOSSARY:0000186',
    "Alternative_sequence"                 => 'ENSGLOSSARY:0000187',
    "Patch"                                => 'ENSGLOSSARY:0000188',
    "Haplotype_(genome)"                   => 'ENSGLOSSARY:0000189',
    "Novel_patch"                          => 'ENSGLOSSARY:0000190',
    "Fix_patch"                            => 'ENSGLOSSARY:0000191',
    "Contig"                               => 'ENSGLOSSARY:0000192',
    "Scaffold"                             => 'ENSGLOSSARY:0000193',
    "Cytogenetic_band"                     => 'ENSGLOSSARY:0000194',
    "Clone"                                => 'ENSGLOSSARY:0000195',
    "BAC"                                  => 'ENSGLOSSARY:0000196',
    "YAC"                                  => 'ENSGLOSSARY:0000197',
    "Cosmid"                               => 'ENSGLOSSARY:0000198',
    "Base_pairs_(genome_size)"             => 'ENSGLOSSARY:0000199',
    "Golden_path_(genome_size)"            => 'ENSGLOSSARY:0000200',
    "Coordinate_system"                    => 'ENSGLOSSARY:0000201',
    "Karyotype"                            => 'ENSGLOSSARY:0000202',
    "PAR"                                  => 'ENSGLOSSARY:0000203',
    "Slice"                                => 'ENSGLOSSARY:0000204',
    "Toplevel"                             => 'ENSGLOSSARY:0000205',
    "Placed_scaffold"                      => 'ENSGLOSSARY:0000206',
    "Unplaced_scaffold"                    => 'ENSGLOSSARY:0000207',
    "Ensembl_sources"                      => 'ENSGLOSSARY:0000208',
    "Gene_source_database"                 => 'ENSGLOSSARY:0000209',
    "GENCODE"                              => 'ENSGLOSSARY:0000210',
    "RefSeq"                               => 'ENSGLOSSARY:0000211',
    "UniProt"                              => 'ENSGLOSSARY:0000212',
    "IMGT"                                 => 'ENSGLOSSARY:0000213',
    "SwissProt"                            => 'ENSGLOSSARY:0000214',
    "TrEMBL"                               => 'ENSGLOSSARY:0000215',
    "INSDC"                                => 'ENSGLOSSARY:0000216',
    "ENA"                                  => 'ENSGLOSSARY:0000217',
    "GenBank_(database)"                   => 'ENSGLOSSARY:0000218',
    "DDBJ"                                 => 'ENSGLOSSARY:0000219',
    "Gene_Ontology"                        => 'ENSGLOSSARY:0000220',
    "HGNC"                                 => 'ENSGLOSSARY:0000221',
    "Rfam"                                 => 'ENSGLOSSARY:0000222',
    "miRbase"                              => 'ENSGLOSSARY:0000223',
    "MGI"                                  => 'ENSGLOSSARY:0000224',
    "zFIN"                                 => 'ENSGLOSSARY:0000225',
    "SGD"                                  => 'ENSGLOSSARY:0000226',
    "UCSC_Genome_Browser"                  => 'ENSGLOSSARY:0000227',
    "Epigenome_source_database"            => 'ENSGLOSSARY:0000228',
    "ENCODE"                               => 'ENSGLOSSARY:0000229',
    "Blueprint_Epigenomes"                 => 'ENSGLOSSARY:0000230',
    "Roadmap_Epigenomics"                  => 'ENSGLOSSARY:0000231',
    "Variation_source_database"            => 'ENSGLOSSARY:0000232',
    "dbSNP"                                => 'ENSGLOSSARY:0000233',
    "EVA"                                  => 'ENSGLOSSARY:0000234',
    "dbVar"                                => 'ENSGLOSSARY:0000235',
    "DGVa"                                 => 'ENSGLOSSARY:0000236',
    "1000_Genomes_project"                 => 'ENSGLOSSARY:0000237',
    "gnomAD"                               => 'ENSGLOSSARY:0000238',
    "TOPMed"                               => 'ENSGLOSSARY:0000239',
    "UK10K"                                => 'ENSGLOSSARY:0000240',
    "HapMap"                               => 'ENSGLOSSARY:0000241',
    "ClinVar"                              => 'ENSGLOSSARY:0000242',
    "Phenotype_source_database"            => 'ENSGLOSSARY:0000243',
    "OMIM"                                 => 'ENSGLOSSARY:0000244',
    "OMIA"                                 => 'ENSGLOSSARY:0000245',
    "Orphanet"                             => 'ENSGLOSSARY:0000246',
    "GWAS_catalog"                         => 'ENSGLOSSARY:0000247',
    "IMPC"                                 => 'ENSGLOSSARY:0000248',
    "Animal_QTLdb"                         => 'ENSGLOSSARY:0000249',
    "HGMD"                                 => 'ENSGLOSSARY:0000250',
    "COSMIC"                               => 'ENSGLOSSARY:0000251',
    "Protein_source_database"              => 'ENSGLOSSARY:0000252',
    "PDB"                                  => 'ENSGLOSSARY:0000253',
    "Algorithm"                            => 'ENSGLOSSARY:0000254',
    "Ensembl_Genebuild"                    => 'ENSGLOSSARY:0000255',
    "Ensembl_Havana"                       => 'ENSGLOSSARY:0000256',
    "Ensembl_Regulatory_Build"             => 'ENSGLOSSARY:0000257',
    "Ensembl_gene_tree_pipeline"           => 'ENSGLOSSARY:0000258',
    "InterProScan"                         => 'ENSGLOSSARY:0000259',
    "BLAST"                                => 'ENSGLOSSARY:0000260',
    "BLAT"                                 => 'ENSGLOSSARY:0000261',
    "DUST"                                 => 'ENSGLOSSARY:0000262',
    "Eponine"                              => 'ENSGLOSSARY:0000263',
    "GeneWise"                             => 'ENSGLOSSARY:0000264',
    "Exonerate"                            => 'ENSGLOSSARY:0000265',
    "Projection_build"                     => 'ENSGLOSSARY:0000266',
    "GENSCAN"                              => 'ENSGLOSSARY:0000267',
    "SIFT"                                 => 'ENSGLOSSARY:0000268',
    "PolyPhen"                             => 'ENSGLOSSARY:0000269',
    "RepeatMasker"                         => 'ENSGLOSSARY:0000270',
    "BLOSUM_62"                            => 'ENSGLOSSARY:0000271',
    "VEP"                                  => 'ENSGLOSSARY:0000272',
    "File_formats"                         => 'ENSGLOSSARY:0000273',
    "HGVS_nomenclature"                    => 'ENSGLOSSARY:0000274',
    "VCF"                                  => 'ENSGLOSSARY:0000275',
    "BED"                                  => 'ENSGLOSSARY:0000276',
    "FASTA"                                => 'ENSGLOSSARY:0000277',
    "BAM/CRAM"                             => 'ENSGLOSSARY:0000278',
    "BigBed"                               => 'ENSGLOSSARY:0000279',
    "Ensembl_default_(VEP)"                => 'ENSGLOSSARY:0000280',
    "BedGraph"                             => 'ENSGLOSSARY:0000281',
    "GTF"                                  => 'ENSGLOSSARY:0000282',
    "GFF"                                  => 'ENSGLOSSARY:0000283',
    "PSL"                                  => 'ENSGLOSSARY:0000284',
    "Wiggle"                               => 'ENSGLOSSARY:0000285',
    "BigWig"                               => 'ENSGLOSSARY:0000286',
    "Pairwise_interactions_(WashU)"        => 'ENSGLOSSARY:0000287',
    "chain"                                => 'ENSGLOSSARY:0000288',
    "Newick"                               => 'ENSGLOSSARY:0000289',
    "EMBL_(file_format)"                   => 'ENSGLOSSARY:0000290',
    "GenBank_(file_format)"                => 'ENSGLOSSARY:0000291',
    "EMF_Alignment_format"                 => 'ENSGLOSSARY:0000292',
    "MAF"                                  => 'ENSGLOSSARY:0000293',
    "MySQL"                                => 'ENSGLOSSARY:0000294',
    "VEP_cache"                            => 'ENSGLOSSARY:0000295',
    "GVF"                                  => 'ENSGLOSSARY:0000296',
    "PhyloXML"                             => 'ENSGLOSSARY:0000297',
    "OrthoXML"                             => 'ENSGLOSSARY:0000298',
    "RDF"                                  => 'ENSGLOSSARY:0000299',
    "AGP"                                  => 'ENSGLOSSARY:0000300',
    "Repeat"                               => 'ENSGLOSSARY:0000301',
    "Repeat_masking"                       => 'ENSGLOSSARY:0000302',
    "Hard_masked"                          => 'ENSGLOSSARY:0000303',
    "Soft_masked"                          => 'ENSGLOSSARY:0000304',
    "Alu_insertion"                        => 'ENSGLOSSARY:0000305',
    "Microsatellite"                       => 'ENSGLOSSARY:0000306',
    "Centromere"                           => 'ENSGLOSSARY:0000307',
    "Low_complexity_regions"               => 'ENSGLOSSARY:0000308',
    "RNA_repeats"                          => 'ENSGLOSSARY:0000309',
    "Satellite_repeats"                    => 'ENSGLOSSARY:0000310',
    "Simple_repeats"                       => 'ENSGLOSSARY:0000311',
    "Tandem_repeats"                       => 'ENSGLOSSARY:0000312',
    "LTRs"                                 => 'ENSGLOSSARY:0000313',
    "Type_I_Transposons/LINE"              => 'ENSGLOSSARY:0000314',
    "Type_I_Transposons/SINE"              => 'ENSGLOSSARY:0000315',
    "Type_II_Transposons"                  => 'ENSGLOSSARY:0000316',
    "Unknown_repeat"                       => 'ENSGLOSSARY:0000317',
    "Alignments"                           => 'ENSGLOSSARY:0000318',
    "Whole_genome_alignment"               => 'ENSGLOSSARY:0000319',
    "Pairwise_whole_genome_alignment"      => 'ENSGLOSSARY:0000320',
    "Multiple_whole_genome_alignment"      => 'ENSGLOSSARY:0000321',
    "Synteny"                              => 'ENSGLOSSARY:0000322',
    "CIGAR"                                => 'ENSGLOSSARY:0000323',
    "Identity"                             => 'ENSGLOSSARY:0000324',
    "Wasabi"                               => 'ENSGLOSSARY:0000325',
    "Similarity"                           => 'ENSGLOSSARY:0000326',
    "Pecan"                                => 'ENSGLOSSARY:0000327',
    "EPO"                                  => 'ENSGLOSSARY:0000328',
    "Progressive_cactus"                   => 'ENSGLOSSARY:0000329',
    "LastZ"                                => 'ENSGLOSSARY:0000330',
    "BlastZ"                               => 'ENSGLOSSARY:0000331',
    "Translated_Blat"                      => 'ENSGLOSSARY:0000332',
    "Regulatory_features"                  => 'ENSGLOSSARY:0000333',
    "Promoters"                            => 'ENSGLOSSARY:0000334',
    "Promoter_flanking_regions"            => 'ENSGLOSSARY:0000335',
    "Enhancers"                            => 'ENSGLOSSARY:0000336',
    "CTCF_binding_sites"                   => 'ENSGLOSSARY:0000337',
    "Transcription_factor_binding_sites"   => 'ENSGLOSSARY:0000338',
    "Open_chromatin_regions"               => 'ENSGLOSSARY:0000339',
    "Regulatory_activity"                  => 'ENSGLOSSARY:0000340',
    "Active"                               => 'ENSGLOSSARY:0000341',
    "Poised"                               => 'ENSGLOSSARY:0000342',
    "Repressed"                            => 'ENSGLOSSARY:0000343',
    "Inactive"                             => 'ENSGLOSSARY:0000344',
    "NA"                                   => 'ENSGLOSSARY:0000345',
    "Epigenome_evidence"                   => 'ENSGLOSSARY:0000346',
    "ChIP-seq"                             => 'ENSGLOSSARY:0000347',
    "DNase_sensitivity"                    => 'ENSGLOSSARY:0000348',
    "Transcription_factor"                 => 'ENSGLOSSARY:0000349',
    "Histone_modification"                 => 'ENSGLOSSARY:0000350',
    "DNA_methylation"                      => 'ENSGLOSSARY:0000351',
    "Bisulfite_sequencing"                 => 'ENSGLOSSARY:0000352',
    "Signal"                               => 'ENSGLOSSARY:0000353',
    "Peak"                                 => 'ENSGLOSSARY:0000354',
    "Transcription_factor_binding_motif"   => 'ENSGLOSSARY:0000355',
    "Epigenome"                            => 'ENSGLOSSARY:0000356',
    "Marker"                               => 'ENSGLOSSARY:0000357',
    "UniSTS"                               => 'ENSGLOSSARY:0000358',
    "External_reference"                   => 'ENSGLOSSARY:0000359',
    "CADD"                                 => 'ENSGLOSSARY:0000360',
    "REVEL"                                => 'ENSGLOSSARY:0000361',
    "MutationAssessor"                     => 'ENSGLOSSARY:0000362',
    "MetaLR"                               => 'ENSGLOSSARY:0000363',
    "MANE"                                 => 'ENSGLOSSARY:0000364',
    "MANE_Select"                          => 'ENSGLOSSARY:0000365',
    "TAGENE"                               => 'ENSGLOSSARY:0000367',
    "Stop_codon_readthrough"               => 'ENSGLOSSARY:0000368',
    "Forward_strand"                       => 'ENSGLOSSARY:0000369',
    "Reverse_strand"                       => 'ENSGLOSSARY:0000370',
    "RefSeq_Match"                         => 'ENSGLOSSARY:0000371',
    "UniProt_Match"                        => 'ENSGLOSSARY:0000372',
    "Nonsense_Mediated_Decay"              => 'ENSGLOSSARY:0000373',
    "Non-ATG_start"                        => 'ENSGLOSSARY:0000374',
    "MANE_Plus_Clinical"                   => 'ENSGLOSSARY:0000375',
    "GENCODE_Comprehensive"                => 'ENSGLOSSARY:0000376'
);

sub new {

    my ( $class, $self ) = @_;
    bless $self, $class;
    return $self;
}

sub data2hash {

    my $self = shift;
    $Data::Dumper::Sortkeys = 1;    # In alphabetic order
    print Dumper ( unbless $self);  # To avoid using {$uid => {$self->{$uid}}
}

sub data2json {

    my $self = shift;
    say encode_json( unbless $self);    # No order
}

sub data2bff {

    my ( $self, $uid, $verbose ) = @_;
    my $data_mapped = mapping2beacon( $self, $uid, $verbose );

    #my $coder       = JSON::XS->new->pretty;
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
        ( $tmp_ref->{biosampleId} ) = keys %{$sample}; # forcing array assignment
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
            my $str_pop = $db . '_' . $pop . '_AF'; # e.g., dbNSFP_1000Gp3_AFR_AF

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
            my (@ids, @ens);
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
      [ 0 + $cursor_crg->{POS_ZERO_BASED} ]; # coercing to number (split values are strings to Perl)
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
                my %clnsigincl = split /[\|:]/, $tmp_var; # ( 816687 => Pathogenic, 816680 => 'Benign' )
                my %clinvar_sig;
                @clinvar_sig{@clndn} = values %clnsigincl; # Assuming @cldn eq keys %clnsigincl
                                                           #print Dumper \%clinvar_sig;
                if ( $clinvar_sig{$key} ) {
                    my $parsed_acmg = parse_acmg_val( $clinvar_sig{$key} );
                    $tmp_ref->{clinicalRelevance} = $parsed_acmg
                      if any { $_ eq $parsed_acmg } @acmg_values;
                }
            }
            else {
                if (
                    exists
                    $cursor_info->{ $map_variant_level_data{clinicalRelevance} }
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
              "HGVSid:$genomic_variations->{identifiers}{genomicHGVSId}", # We leverage the previous parsing
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
