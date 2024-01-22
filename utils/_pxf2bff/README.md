# NAME

**THIS IS SCRIPT IS DEPRECATED**

PLEASE USE [CONVERT\_PHENO](https://github.com/CNAG-Biomedical-Informatics/convert-pheno) INSTEAD

A script that converts Phenopacket PXF (JSON) to BFF (JSON)

# SYNOPSIS

pxf2bff -i <\*.json> \[-options\]

     Arguments:                       
       -i|input                       Phenopacket JSON files

     Options:
       -o|out-dir                     Output (existing) directory for the BFF files
       -h|help                        Brief help message
       -man                           Full documentation
       -debug                         Print debugging (from 1 to 5, being 5 max)
       -verbose                       Verbosity on
     

# CITATION

The author requests that any published work that utilizes **B2RI** includes a cite to the the following reference:

Rueda, M, Ariosa R. "Beacon v2 Reference Implementation: a toolkit to enable federated sharing of genomic and phenotypic data". _Bioinformatics_, btac568, https://doi.org/10.1093/bioinformatics/btac568

# SUMMARY

A script that converts Phenopacket PXF (JSON) to BFF (JSON).

Note that PXF contain one individual per file (1 JSON document), whereas BFF (majoritarily) contain multiple inviduals per file (JSON array of documentsa). Thus, the input should be PXF JSON from, say, the same dataset, and the output will be a unique `individuals.json` file.

_NB:_ The script was created to parse [RD\_Connect synthetic data](https://ega-archive.org/datasets/EGAD00001008392). See examples in the `in` and `out` directories. 

The script is **UNTESTED** for other PXFs. Please use at your own risk!

**UPDATE: Aug-2022**: The author is working in an improved version that will extend its capabilities.

# HOW TO RUN PXF2BFF

The script runs on command-line Linux (tested on Debian-based distribution). Perl 5 is installed by default on Linux,
but we will need to install a few CPAN modules.

First we install cpanminus (with sudo privileges):

    $ sudo apt-get install cpanminus

Second we use cpanm to install the CPAN modules:

(Note that first you need to copy the following [cpanfile](https://raw.githubusercontent.com/EGA-archive/beacon2-ri-tools/main/cpanfile) to your current directory).

    $ cpanm --sudo --installdeps .

If you prefer to have the dependencies in a "virtual environment" (i.e., install the CPAN modules in the directory of the application) we recommend using the module Carton.

    $ cpanm --sudo Carton

Then, we can install our dependencies:

    $ carton install

For executing `pxf2bff` you will need:

- Input file(s):

    A list of Phenopacket JSON files (normally from the same dataset). Note that PXFs only contain ONE individual per file.

**Examples:**

    $ ./pxf2bff -i in/*json -o out

    $ $path/pxf2bff -i file.json --out-dir my_bff_outdir

    $ $path/pxf2bff -i my_indir/*json -o my_bff_outdir 

    $ carton exec -- $path/pxf2bff -i my_indir/*json -o my_bff_outdir # if using Carton

## COMMON ERRORS AND SOLUTIONS

    * Error message: Foo
      Solution: Bar

    * Error message: Foo
      Solution: Bar

# AUTHOR 

Written by Manuel Rueda, PhD. Info about CRG can be found at [https://www.crg.eu](https://www.crg.eu).

# REPORTING BUGS

Report bugs or comments to <manuel.rueda@crg.eu>.

# COPYRIGHT

This PERL file is copyrighted. See the LICENSE file included in this distribution.
