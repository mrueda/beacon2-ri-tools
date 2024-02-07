[![Docker build](https://github.com/mrueda/beacon2-ri-tools/actions/workflows/docker-build.yml/badge.svg)](https://github.com/mrueda/beacon2-ri-tools/actions/workflows/docker-build.yml)
[![Documentation Status](https://readthedocs.org/projects/b2ri-documentation/badge/?version=latest)](https://b2ri-documentation.readthedocs.io/en/latest/?badge=latest)
![Maintenance status](https://img.shields.io/badge/maintenance-actively--developed-brightgreen.svg)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Docker Pulls](https://badgen.net/docker/pulls/manuelrueda/beacon2-ri-tools?icon=docker&label=pulls)](https://hub.docker.com/r/manuelrueda/beacon2-ri-tools/)
[![Docker Pulls EGA-archive](https://badgen.net/docker/pulls/beacon2ri/beacon_reference_implementation?icon=docker&label=EGA-archive-pulls)](https://hub.docker.com/r/beacon2ri/beacon_reference_implementation/)
![version](https://img.shields.io/badge/version-2.0.1-blue)

**Documentation**: <a href="https://b2ri-documentation.readthedocs.io/" target="_blank">https://b2ri-documentation.readthedocs.io/</a>

**CLI Source Code**: <a href="https://github.com/mrueda/beacon2-ri-tools" target="_blank">https://github.com/mrueda/beacon2-ri-tools</a>

**Docker Hub Image**: <a href="https://hub.docker.com/r/manuelrueda/beacon2-ri-tools/tags" target="_blank">https://hub.docker.com/r/manuelrueda/beacon2-ri-tools/tags</a>

# NAME

`beacon`: A script to **annotate** and **transform** genomic variations data (**VCF**) to queryable data (**MongoDB**)

(Actively maintained by the original author)

# SYNOPSIS

beacon &lt;mode> \[-arguments\] \[-options\]

    Mode:
      vcf 
        -i|input                       Requires a VCF.gz file
                                       (May require a parameters file)

      mongodb
                                       (May require a parameters file)

      full (vcf + mongodb)
        -i|input                       Requires a VCF.gz file
                                       (May require a parameters file)

    Options:
        -h|help                        Brief help message
        -man                           Full documentation
        -v                             Version
        -c                             Requires a configuration file
        -p                             Requires a parameters file
        -n                             Number of cpus/cores/threads
        -debug                         Print debugging (from 1 to 5, being 5 max)
        -verbose                       Verbosity on
        -nc|-no-color                  Don't print colors to STDOUT

        (For convenience, specifiers may have a leading - or --)

# DESCRIPTION

**beacon2-ri-tools** repository, part of the ELIXIR-CRG Beacon v2 Reference Implementation (B2RI), includes:

- The `beacon` script
- A suite of [utilities](https://github.com/mrueda/beacon2-ri-tools/tree/main/utils) aiding in data ingestion

### `beacon`

`beacon`, a script with three operational modes for diverse actions:

- Mode vcf

    Converts **genomic variation data** (VCF) into queryable MongoDB format. Extended documentation is available [here](https://b2ri-documentation.readthedocs.io/en/latest/data-ingestion). The VCF data are annotated and serialized into `genomicVariationsVcf.json.gz`.

- Mode mongodb

    Facilitates loading [BFF](#what-is-the-beacon-friendly-format-bff) data into MongoDB.

- Mode full: Combines vcf and mongodb

### B2RI diagram

                * Beacon v2 Reference Implementation *

                    ___________
                    |          |
              XLSX  | Metadata | (incl. Phenotypic data)
                    |__________|
                         |
                         |
                         | Validation (bff-validator)
                         |
     _________       ____v____        __________         ______
     |       |       |       |       |          |        |     | <---- Request
     |  VCF  | ----> |  BFF  | ----> | Database | <----> | API | 
     |_______|       |_ _____|       |__________|        |_____| ----> Response
                         |             MongoDB             
              beacon     |    beacon                       
                         |    
                         |
                      Optional
                         |
                   ______v_______
                   |            |
                   | BFF        |
                   | Genomic    | Visualization
                   | Variations |
                   | Browser    |
                   |____________|
     
    ------------------------------------------------|||------------------------
    beacon2-ri-tools                                             beacon2-ri-api

# INSTALLATION

We provide two installation options for `beacon2-ri-tools`, one containerized (recommended) and another non-containerized.

## Containerized

### Method 1: From Docker Hub

Download a docker image (latest version) from [Docker Hub](https://hub.docker.com/r/manuelrueda/beacon2-ri-tools) by executing:

    docker pull manuelrueda/beacon2-ri-tools:latest
    docker image tag manuelrueda/beacon2-ri-tools:latest crg/beacon2_ri:latest

See additional instructions below.

### Method 2: From Dockerfile

Download the `Dockerfile` from [Github](https://github.com/mrueda/beacon2-ri-tools/blob/main/Dockerfile) by typing:

    wget https://raw.githubusercontent.com/mrueda/beacon2-ri-tools/main/Dockerfile

Then execute the following commands:

    docker buildx build -t crg/beacon2_ri:latest . # build the container (~1.1G)

### Additional instructions for Methods 1 and 2

**IMPORTANT:** Docker containers are fully isolated. If you think you'll have to mount a volume to the container please read the section [Mounting Volumes](#mounting-volumes) before proceeding further.

**IMPORTANT (BIS):** If you plan to load data into MongoDB from inside `beacon2-ri-tools` container please read the section [Access MongoDB from inside the container](#access-mongodb-from-inside-the-container) before proceeding further.

    docker run -tid --name beacon2-ri-tools crg/beacon2_ri:latest # run the image detached
    docker ps  # list your containers, beacon2-ri-tools should be there
    docker exec -ti beacon2-ri-tools bash # connect to the container interactively

After the `docker exec` command, you will land at `/usr/share/beacon-ri/`, then execute:

    nohup beacon2-ri-tools/lib/BEACON/bin/deploy_external_tools.sh &

...that will inject the external tools and DBs into the image and modify the [configuration](#readme-md-setting-up-beacon) files. It will also run a test to check that the installation was succesful. Note that running `deploy_external_tools.sh` will take some time (and disk space!!!). You can check the status by using:

    tail -f nohup.out

The last step is to deploy MongoDB. We will deploy it **outside** the `beacon2-ri-tools` container so please `exit` from it.

Please download the `docker-compose.yml` file: 

    wget https://raw.githubusercontent.com/mrueda/beacon2-ri-tools/main/docker-compose.yml

And then execute:

    docker-compose up -d

Mongo Express will be accessible via `http://localhost:8081` with default credentials `admin` and `pass`.

### Mounting volumes

It's simpler to mount a volume when starting a container than to add it to an existing one. If you need the mount a volume to the container please use the following syntax (`-v host:container`). Find an example below (note that you need to change the paths to match yours):

    docker run -tid --volume /media/mrueda/4TBT/workdir:/workdir --name beacon2-ri-tools crg/beacon2_ri:latest

Now you'll need to execute:

    docker exec -ti beacon2-ri-tools bash # connect to the container interactively

After the `docker exec` command, you will land at `/usr/share/beacon-ri/`, then execute:

    nohup beacon2-ri-tools/lib/BEACON/bin/deploy_external_tools.sh & # see above why

Then, you can run commands **inside the container**, like this;

    # We connect to the container interactively
    docker exec -ti beacon2-ri-tools bash
    # We go to the mounting point
    cd /workdir 
    # We run the executable
    /usr/share/beacon-ri/beacon2-ri-tools/beacon vcf -i example.vcf.gz -p param.in

Alternatively, you can run commands **from the host**, like this:

    # First we create an alias to simplify invocation
    alias beacon='docker exec -ti beacon2-ri-tools /usr/share/beacon-ri/beacon2-ri-tools/beacon'
    # Now we use a text editor to edit the file <params.in> to include the parameter 'projectdir'
    projectdir /workdir/my_fav_job_id
    # Finally we use the alias to run the command
    beacon vcf -i /workdir/my_vcf.gz -p /workdir/param.in 

### Access MongoDB from inside the container

If you want to load data from **inside** the `beacon2-ri-tools` directly to `mongo` container, both containers have to be on the same network:

    docker network ls # find available networks
    docker run -tid --network=mrueda_default_network --name beacon2-ri-tools crg/beacon2_ri:latest # change the network to match yours

## Non containerized

Download the latest version from [Github](https://github.com/mrueda/beacon2-ri-tools):

    tar -xvf beacon2-ri-tools-2.0.0.tar.gz    # Note that naming may be different

Alternatively, you can use git clone to get the latest (stable) version

    git clone https://github.com/mrueda/beacon2-ri-tools.git

`beacon` is a Perl script (no compilation needed) that runs on Linux command-line. Internally, it submits multiple pipelines via customizable Bash scripts (see example [here](https://github.com/mrueda/beacon2-ri-tools/blob/main/lib/BEACON/bin/run_vcf2bff.sh)). Note that Perl and Bash are installed by default in Linux, but we will need to install a few dependencies.

(For Debian and its derivatives, Ubuntu, Mint, etc.)

First we install `cpmanminus` utility:

    sudo apt-get install cpanminus

Also, to read the documentation you'll need `perldoc` that may or may not be installed in your Linux distribution:

    sudo apt-get install perl-doc

Second we use `cpanm` to install the CPAN modules. You have two choose between one of the 2 options below. Change directory into the `beacon2-ri-tools` folder and run:

**Option 1:** System-level installation:

    cpanm --notest --sudo --installdeps .

**Option 2:** Install the dependencies at `~/perl5`

    cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
    cpanm --notest --installdeps .

To ensure Perl recognizes your local modules every time you start a new terminal, you should type:

    echo 'eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)' >> ~/.bashrc

`beacon` also needs that **bcftools**, **SnpEff** and **MongoDB** are installed. See [external software](https://b2ri-documentation.readthedocs.io/en/latest/download-and-installation/#non-containerized-version-data-ingestion-tools) for more info.

### Setting up beacon

Before running anything you need to set-up the **configuration file**:

The configuration file is a [YAML](https://es.wikipedia.org/wiki/YAML) text file with locations for executables and files needed for the job (e.g., SnpEff jar files, dbSNSFP database).

You have two options here:

    * RECOMMENDED: You set the config file ONCE. This file will serve for all your jobs.
      To set it up go to the installation directory and modify the file 'config.yaml' with your paths.

    * You provide the config file with the argument -c when you run a
      job. This is useful if you want to override the "main" file (see above).

Below are parameters that can be modified by the user along with their default values.
Please remember to leave a blank space between the parameter and the value.

**Configuration file** (YAML)

    ---
    # Reference assemblies (genomes)
    hs37fasta: /path
    hg19fasta: /path
    hg38fasta: /path

    # ClinVar
    hg19clinvar: /path
    hg38clinvar: /path

    # Cosmic 
    hg19cosmic: /path
    hg38cosmic: /path

    # dbSNSFP Academic
    hg19dbnsfp: /path
    hg38dbnsfp: /path

    # Miscellanea software
    snpeff: /path
    snpsift: /path
    bcftools: /path

    # Max RAM memory for snpeff (optional)
    mem: 8G

    # MongoDB 
    mongoimport: /path
    mongostat: /path
    mongosh: /path
    mongodburi: string

    # Temporary directory (optional)
    tmpdir: /path

Please find below a detailed description of all parameters (alphabetical order):

- **bcftools**

    Location of the bcftools exe (e.g., /home/foo/bcftools\_1.11/bcftools).

- **dbnsfpset**

    The set of fields to be taken from dbNSFP database.

    Values: &lt;all> or &lt;ega>

- **genome**

    Your reference genome.

    Accepted values: hg19, hg38 and hs37.

    If you used GATKs GRCh37/b37 set it to hg19.

    Not supported  : NCBI36/hg18, NCBI35/hg17, NCBI34/hg16, hg15 and older.

- **hg19{clinvar,cosmic,dbnsfp,fasta}**

    Path for each of these files. COSMIC annotations are added but not used (v2.0.0).

- **hg38{clinvar,cosmic,dbnsfp,fasta}**

    Path for each of these files. COSMIC annotations are added but not used (v2.0.0).

- **hs37**

    Path for ithe reference genome hs37.

- **mem**

    RAM memory for the Java processes (e.g., 8G).

- **mongoXYZ**

    Parameters needed for MongoDB.

- **paneldir**

    A directory where you can store text files (consisting of a column with a lists of genes) to be displayed by the BFF Genomic Variations Browser.

- **snpeff**

    Location of the java archive dir (e.g., /home/foo/snpEff/snpEff.jar).

- **snpsift**

    Location of the java archive dir (e.g., /home/foo/snpEff/snpSift.jar).

- **tmpdir**

    Use if you a have a preferred tmpdir.

### System requirements

    * Ideally a Debian-based distribution (Ubuntu or Mint), but any other (e.g., CentOs, OpenSuse) should do as well (untested).
    * Perl 5 (>= 5.10 core; installed by default in most Linux distributions). Check the version with "perl -v"
    * 4GB of RAM (ideally 16GB).
    * >= 1 cores (ideally i7 or Xeon).
    * At least 200GB HDD.
    * bcftools, SnpEff and MongoDB

The Perl itself does not need a lot of RAM (max load will reach 400MB) but external tools do (e.g., process `mongod` \[MongoDB's daemon\]).

### Testing the code

I am not using any CPAN's module to perform unit tests. When I modify the code my "integration tests" are done by comparing to reference files. You can validate the installation using the files included in the [test](https://github.com/mrueda/beacon2-ri-tools/tree/main/test) directory.

# HOW TO RUN `beacon`

We recommend following this [tutorial](https://b2ri-documentation.readthedocs.io/en/latest/tutorial-data-beaconization).

This script has three **modes**: `vcf, mongodb` and `full`

**\* Mode `vcf`**

Annotating and serializing a VCF file into a BFF file for genomic variations.

**\* Mode `mongodb`**

Loading BFF data into MongoDB.

**\* Mode `full`**

Mode vcf + mode mongodb.

To perform all these taks you'll need: 

- A gzipped VCF 

    Note that it does not need to be bgzipped.

- (Optional) A parameters file

    A parameters text file that will contain specific values needed for the job.

- BFF files (only for modes: mongodb and full)

    (see explanation of BFF format [here](#what-is-the-beacon-friendly-format-bff))

- (Optional) Specify the number of cores (only for VCF processing!)

    The number of threads/cores you want to use for the job. In this regard (since SnpEff does not deal well with parallelization) we recommend using `-n 1` and running multiple simultaneous jobs with GNU `parallel` or the included [queue system](https://github.com/mrueda/beacon2-ri-tools/tree/main/utils/bff_queue)). The software scales linearly {O}(n) with the number of variations present in the input file. The easiest way is to run one job per chromosome, but if you are in a hurry and have many cores you can split each chromosome into smaller vcfs.

`beacon` will create an independent project directory `projectdir` and store all needed information needed there. Thus, many concurrent calculations are supported.
Note that `beacon` will treat your data as _read-only_ (i.e., will not modify your original files).

**Annex: Parameters file**  (YAML)

    --
    bff:
      metadatadir: .
      analyses: analyses.json
      biosamples: biosamples.json
      cohorts: cohorts.json
      datasets: datasets.json
      individuals: individuals.json
      runs: runs.json
      # Note that genomicVariationsVcf is not affected by <metadatadir>
      genomicVariationsVcf: beacon_XXXX/vcf/genomicVariationsVcf.json.gz
    datasetid: crg_beacon_test
    genome: hs37
    bff2html: true
    projectdir: my_project

Please find below a detailed description of all parameters (alphabetical order):

- **bff**

    Location for the Beacon Friendly Format JSON files.

- **center**

    Experimental feature. Not used for now.

- **datasetid**

    An unique identifier for the dataset present in the input VCF. Default value is 'id\_1'

- **ega**

    (For EGA internal use only)

    egac: EGA DAC Accession ID.

    egad: EGA Dataset Accession ID.

    egas: EGA Study Accession ID.

- **genome**

    Your reference genome.

    Accepted values: hg19, hg38 and hs37.

    If you used GATKs GRCh37/b37 set it to hg19.

    Not supported: NCBI36/hg18, NCBI35/hg17, NCBI34/hg16, hg15 and older.

- **organism**

    Experimental feature. Not used for now.

- **bff2html**

    Set bff2html to `true` to activate BFF Genomic Variations Browser.

- **projectdir**

    The prefix for dir name (e.g., 'cancer\_sample\_001'). Note that it can also contain a path (e.g., /workdir/cancer\_sample\_001).
    The script will automatically add an unique identifier to each job.

- **technology**

    Experimental feature. Not used for now.

**Optional:** The user has the option of turning on the **BFF Genomic Variatons Browser**. With this option enabled, an HTML file will be created to be used with a web browser.
The purpose of such HTML file is to provide a preliminary exploration of the genomic variations data. See the full documentation [here](https://b2ri-documentation.readthedocs.io/en/latest/data-ingestion/#bff-genomic-variations-browser).

**Examples:**

    $ ./beacon vcf -i input.vcf.gz 

    $ ./beacon mongodb -p param_file  # MongoDB load only

    $ ./beacon full -n 1 --i input.vcf.gz -p param_file  > log 2>&1

    $ ./beacon full -n 1 --i input.vcf.gz -p param_file -c config_file > log 2>&1

    $ nohup $path_to_beacon/beacon full -i input.vcf.gz -verbose

    $ parallel "./beacon vcf -n 1 -i chr{}.vcf.gz  > chr{}.log 2>&1" ::: {1..22} X Y

_NB_: If you don't want colors in the output use the flag `--no-color`. If you did not use the flag and want to get rid off the colors in your printed log file use this command to parse ANSI colors:

    perl -pe 's/\x1b\[[0-9;]*[mG]//g'

## WHAT IS THE BEACON FRIENDLY FORMAT (BFF)

Beacon Friendly Format is a set of 7 JSON files (JSON arrays consisting of multiple documents) that match the 7 schemas from [Beacon v2 Models](https://docs.genomebeacons.org/schemas-md/analyses_defaultSchema/).

Six files correspond to Metadata (`analyses.json,biosamples.json,cohorts.json,datasets.json,individuals.json,runs.json`) and one corresponds to variations (`genomicVariations.json`).

Normally, `beacon` script is used to create `genomicVariations` JSON file. The other 6 files are created with [this utility](https://github.com/mrueda/beacon2-ri-tools/tree/main/utils/bff_validator) (part of the distribution). See instructions [here](https://github.com/mrueda/beacon2-ri-tools/tree/main/utils/bff_validator/README.md).

Once we have all seven files, then we can proceed to load the data into MongoDB.

# COMMON ERRORS: SYMPTOMS AND TREATMENT

    * Dockerfile:
            * DNS errors
              - Error: Temporary failure resolving 'foo'
                Solution: https://askubuntu.com/questions/91543/apt-get-update-fails-to-fetch-files-temporary-failure-resolving-error
    * Perl: 
            * Compilation errors:
              - Error: Unknown PerlIO layer "gzip" at (eval 10) line XXX
                Solution: cpanm --sudo PerlIO::gzip
                             ... or ...
                      sudo apt-get install libperlio-gzip-perl
            * Execution errors:
              - Error with YAML::XS
                Solution: Make sure the YAML (config.yaml or parameters file) is well formatted (e.g., space after param:' ').

    * Bash: 
            (Possible errors that can happen when the embeded Bash scripts are executed)
            * bcftools errors: bcftools is nit-picky about VCF fields and nomenclature of contigs/chromosomes in reference genome
                   => Failed to execute: beacon_161855926405757/run_vcf2bff.sh
                      Please check this file beacon_161855926405757/run_vcf2bff.log
              - Error: 
                     # Running bcftools
                     [E::faidx_adjust_position] The sequence "22" was not found
                Solution: Make sure you have set the correct genome (e.g., hg19, hg38 or hs37) in parameters_file.
                          In this case bcftools was expecting to find 22 in the <*.fa.gz> file from reference genome, but found 'chr22' instead.
                    Tips:
                         - hg{19,38} use 'chr' in chromosome naming (e.g., chr1)
                         - hs37 does not use 'chr' in chromosome naming (e.g., 1)
          
               - Error
                    # Running bcftools
                    INFO field IDREP only contains 1 field, expecting 2
                 Solution: Please Fix VCF info field manually (or get rid of problematic fields with bcftools)
                           e.g., bcftools annotate -x INFO/IDREP input.vcf.gz | gzip > output.vcf.gz
                                 bcftools annotate -x INFO/MLEAC,INFO/MLEAF,FMT/AD,FMT/PL input.vcf.gz  | gzip > output.vcf.gz
               
                     
      NB: The bash scripts can be executed "manually" in the beacon_XXX dir. You must provide the 
          input vcf as an argument. This is a good option for debugging. 

## KNOWN ISSUES

    * Some Linux distributions do not include perldoc and thus Perl's library Pod::Usage will complain.
      Please, install it (sudo apt-get install perl-doc) if needed.

# CITATION

The author requests that any published work that utilizes **B2RI** includes a cite to the the following reference:

Rueda, M, Ariosa R. "Beacon v2 Reference Implementation: a toolkit to enable federated sharing of genomic and phenotypic data". _Bioinformatics_, btac568, https://doi.org/10.1093/bioinformatics/btac568

# AUTHOR

Written by Manuel Rueda, PhD. Info about CRG can be found at [https://www.crg.eu](https://www.crg.eu)

Credits: 

    * Sabela De La Torre (SDLT) created a Bash script for Beacon v1 to parse vcf files L<https://github.com/ga4gh-beacon/beacon-elixir>.
    * Toshiaki Katayamai re-implemented the Beacon v1 script in Ruby.
    * Later Dietmar Fernandez-Orth (DFO) modified the Ruby for Beacon v2 L<https://github.com/ktym/vcftobeacon and added post-processing with R, from which I borrowed ideas to implement vcf2bff.pl.
    * DFO for usability suggestions and for creating bcftools/snpEff commands.
    * Roberto Ariosa for help with MongoDB implementation.
    * Mauricio Moldes helped with the containerization.

# REPORTING BUGS

For Beacon problems, questions, or suggestions, send an e-mail to manuel.rueda@cnag.eu.

# COPYRIGHT and LICENSE

This PERL file is copyrighted, (C) 2021-2024 Manuel Rueda. See the LICENSE file included in this distribution.
