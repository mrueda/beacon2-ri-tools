# NAME

vcf2bff: A script for parsing annotated vcf files and transforming the data to the format needed for Beacon v2.

# SYNOPSIS

vcf2bff.pl -i &lt;vcf\_file> \[-arguments|-options\]

     Arguments:                       
       -i|input                       Annotated vcf file
       -d|dataset-id                  Dataset ID
       -g|genome                      Reference genome
       -p|project-dir                 Beacon project dir

     Options:
       -f|format                      Output format [>bff|hash|json]
       -out-dir                       Output directory

     Generic Options:
       -h|help                        Brief help message
       -man                           Full documentation
       -debug                         Print debugging (from 1 to 5, being 5 max)
       -verbose                       Verbosity on

# SUMMARY

Script to parse a VCF having SnepEff/SnpSift annotations (ANN fields).

The output can be:

       a) genomicVariantsVcf.json.gz [bff]

For development:

       b) genomicVariationsVcf-dev.bff.gz Standard JSON [bff-pretty]
       c) genomicVariationsVcf-dev.json.gz Standard JSON [json]
       d) genomicVariationsVcf-dev.hash.gz Perl hash data structure [hash]

# INSTALLATION

This script should come preinstalled with `beacon2-cbi-tools`. Otherwise use the `cpanfile` from ../..

    $ sudo apt-get install libperlio-gzip-perl
    $ cpanm --installdeps ../..

# HOW TO RUN VCF2BFF

For executing vcf2bff you will need:

- 1 - Input file

    VCF file.

- 2 - Dataset ID

    String.

- 3 - Reference genome

    String.

- 4 - Project dir

    String.

    Optional:

- 5 - Format

    \[bff | bff-pretty | json | hash \]

From version **2.0.8** we have a `config.yaml` file with the data for `annotatedWith`.

**Examples:**

    ./vcf2bff.pl -i file.vcf.gz --dataset-id my_id_1 --genome hg19 --project-dir my_project_dir
    ./vcf2bff.pl -i file.vcf.gz --dataset-id my_id_1 --genome hg19 --project-dir my_project_dir -f json

# CITATION

The author requests that any published work that utilizes **B2RI** includes a cite to the following reference:

Rueda, M, Ariosa R. "Beacon v2 Reference Implementation: a toolkit to enable federated sharing of genomic and phenotypic data". _Bioinformatics_, btac568, https://doi.org/10.1093/bioinformatics/btac568

# AUTHOR 

Written by Manuel Rueda, PhD. Info about CNAG can be found at [https://www.cnag.eu](https://www.cnag.eu).

Credits: Toshiaki Katayamai & Dietmar Fernandez-Orth for creating an initial Ruby/R version [https://github.com/ktym/vcftobeacon](https://github.com/ktym/vcftobeacon) 
from which I borrowed the concept for creating vcf2bff.pl.

# COPYRIGHT

This PERL file is copyrighted. See the LICENSE file included in this distribution.
