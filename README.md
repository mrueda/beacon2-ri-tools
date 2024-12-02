[![Docker build](https://github.com/mrueda/beacon2-ri-tools/actions/workflows/docker-build.yml/badge.svg)](https://github.com/mrueda/beacon2-ri-tools/actions/workflows/docker-build.yml)
[![Documentation Status](https://readthedocs.org/projects/b2ri-documentation/badge/?version=latest)](https://b2ri-documentation.readthedocs.io/en/latest/?badge=latest)
![Maintenance status](https://img.shields.io/badge/maintenance-actively--developed-brightgreen.svg)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Docker Pulls](https://badgen.net/docker/pulls/manuelrueda/beacon2-ri-tools?icon=docker\&label=pulls)](https://hub.docker.com/r/manuelrueda/beacon2-ri-tools/)
[![Docker Pulls EGA-archive](https://badgen.net/docker/pulls/beacon2ri/beacon_reference_implementation?icon=docker\&label=EGA-archive-pulls)](https://hub.docker.com/r/beacon2ri/beacon_reference_implementation/)
![version](https://img.shields.io/badge/version-2.0.4-blue)

**Documentation**: <a href="https://b2ri-documentation.readthedocs.io/" target="_blank">https://b2ri-documentation.readthedocs.io/</a>

**CLI Source Code**: <a href="https://github.com/mrueda/beacon2-ri-tools" target="_blank">https://github.com/mrueda/beacon2-ri-tools</a>

**Docker Hub Image**: <a href="https://hub.docker.com/r/manuelrueda/beacon2-ri-tools/tags" target="_blank">https://hub.docker.com/r/manuelrueda/beacon2-ri-tools/tags</a>

**Actively maintained by the original author**

# Description

**beacon2-ri-tools** repository, part of the ELIXIR-Beacon v2 Reference Implementation (B2RI), includes:

- The [beacon](https://github.com/mrueda/beacon2-ri-tools/tree/main/bin/README.md) script
- A suite of [utilities](https://github.com/mrueda/beacon2-ri-tools/tree/main/utils) aiding in data ingestion
- The [CINECA_synthetic_cohort_EUROPE_UK1](https://github.com/mrueda/beacon2-ri-tools/tree/main/CINECA_synthetic_cohort_EUROPE_UK1) dataset

### B2RI diagram

                * Beacon v2 Reference Implementation *

                    ___________
              XLSX  |          |
               or   | Metadata | (incl. Phenotypic data)
              JSON  |__________|
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

## Roadmap 

**Latest Update: Nov-2024**

We know that this repository has been downloaded and used in many Beacon v2 implementations, so our plan is to keep supporting it and improving it. These are our plans:

- **Implement Beacon 2.1 changes**

    For `VCF`, this will imply adopting VRS nomenclature and maybe moving away from `LegacyVariation`. Adding support for Structural variants if present.

    For other entities, make sure that we follow the latest schema in `bff-validator`, and the Excel file.

    Update **CINECA** synthetic dataset.

- **Improve Genomic Variations Browser**

    So that it works as a web-server instead of a static web-page.

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

    # Docker Version 19.03 and Above (Supports buildx)
    docker buildx build -t crg/beacon2_ri:latest . # build the container (~1.1G)

    # Docker Version Older than 19.03 (Does Not Support buildx)
    docker build -t crg/beacon2_ri:latest . # build the container (~1.1G)

### Additional instructions for Methods 1 and 2

If MongoDB has not been installed alongside the `beacon2-ri-api` repository, it will be necessary to install it separately. MongoDB should be deployed outside the `beacon2-ri-tools` container.

Please download the `docker-compose.yml` file:

    wget https://raw.githubusercontent.com/mrueda/beacon2-ri-tools/main/docker-compose.yml

And then execute:

    docker network create my-app-network
    docker-compose up -d

Mongo Express will be accessible via `http://localhost:8081` with default credentials `admin` and `pass`.

**IMPORTANT:** Docker containers are fully isolated. If you think you'll have to mount a volume to the container please read the section [Mounting Volumes](#mounting-volumes) before proceeding further.

**IMPORTANT (BIS):** If you plan to load data into MongoDB from inside `beacon2-ri-tools` container please read the section [Access MongoDB from inside the container](#access-mongodb-from-inside-the-container) before proceeding further.

    docker run -tid --name beacon2-ri-tools crg/beacon2_ri:latest # run the image detached
    docker ps  # list your containers, beacon2-ri-tools should be there
    docker exec -ti beacon2-ri-tools bash # connect to the container interactively

After the `docker exec` command, you will land at `/usr/share/beacon-ri/`, then execute:

    nohup beacon2-ri-tools/lib/BEACON/bin/deploy_external_tools.sh &

...that will inject the external tools and DBs into the image and modify the [configuration](#readme-md-setting-up-beacon) files. It will also run a test to check that the installation was successful. Note that running `deploy_external_tools.sh` will take some time (and disk space!!!). You can check the status by using:

    tail -f nohup.out

### Mounting volumes

It's simpler to mount a volume when starting a container than to add it to an existing one. If you need to mount a volume to the container please use the following syntax (`-v host:container`). Find an example below (note that you need to change the paths to match yours):

    docker run -tid --volume /media/mrueda/4TBT/workdir:/workdir --name beacon2-ri-tools crg/beacon2_ri:latest

Now you'll need to execute:

    docker exec -ti beacon2-ri-tools bash # connect to the container interactively

After the `docker exec` command, you will land at `/usr/share/beacon-ri/`, then execute:

    nohup beacon2-ri-tools/lib/BEACON/bin/deploy_external_tools.sh & # see above why

Then, you can run commands **inside the container**, like this:

    # We connect to the container interactively
    docker exec -ti beacon2-ri-tools bash
    # We go to the mounting point
    cd /workdir
    # We run the executable
    /usr/share/beacon-ri/beacon2-ri-tools/bin/beacon vcf -i example.vcf.gz -p param.in

Alternatively, you can run commands **from the host**, like this:

    # First we create an alias to simplify invocation
    alias beacon='docker exec -ti beacon2-ri-tools /usr/share/beacon-ri/beacon2-ri-tools/beacon'
    # Now we use a text editor to edit the file <params.in> to include the parameter 'projectdir'
    projectdir /workdir/my_fav_job_id
    # Finally we use the alias to run the command
    beacon vcf -i /workdir/my_vcf.gz -p /workdir/param.in

### Access MongoDB from inside the container

If you want to load data from **inside** the `beacon2-ri-tools` directly to `mongo` container, both containers have to be on the same network:

    docker run -tid --network=my-app-network --name beacon2-ri-tools crg/beacon2_ri:latest # change the network to match yours

## Non-containerized

Download the latest version from [Github](https://github.com/mrueda/beacon2-ri-tools):

    tar -xvf beacon2-ri-tools-2.0.0.tar.gz    # Note that naming may be different

Alternatively, you can use git clone to get the latest (stable) version:

    git clone https://github.com/mrueda/beacon2-ri-tools.git

`beacon` is a Perl script (no compilation needed) that runs on Linux command-line. Internally, it submits multiple pipelines via customizable Bash scripts (see example [here](https://github.com/mrueda/beacon2-ri-tools/blob/main/lib/BEACON/bin/run_vcf2bff.sh)). Note that Perl and Bash are installed by default in Linux, but we will need to install a few dependencies.

(For Debian and its derivatives, Ubuntu, Mint, etc.)

First, we install `cpanminus` utility:

    sudo apt-get install cpanminus

Also, to read the documentation you'll need `perldoc` that may or may not be installed in your Linux distribution:

    sudo apt-get install perl-doc

Second, we use `cpanm` to install the CPAN modules. You have to choose between one of the 2 options below. Change directory into the `beacon2-ri-tools` folder and run:

**Option 1:** System-level installation:

    cpanm --notest --sudo --installdeps .

**Option 2:** Install the dependencies at `~/perl5`:

    cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
    cpanm --notest --installdeps .

To ensure Perl recognizes your local modules every time you start a new terminal, you should type:

    echo 'eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)' >> ~/.bashrc

`beacon` also needs that **bcftools**, **SnpEff**, and **MongoDB** are installed. See [external software](https://b2ri-documentation.readthedocs.io/en/latest/download-and-installation/#non-containerized-beacon2-ri-tools) for more info.

## Setting up beacon

Before running anything, you need to set up the **configuration file**:

The configuration file is a [YAML](https://es.wikipedia.org/wiki/YAML) text file with locations for executables and files needed for the job (e.g., SnpEff jar files, dbSNSFP database).

You have two options here:

- **RECOMMENDED:** You set the config file ONCE. This file will serve for all your jobs.
  To set it up, go to the installation directory and modify the file `config.yaml` with your paths.

- You provide the config file with the argument `-c` when you run a job. This is useful if you want to override the "main" file (see above).

Below are parameters that can be modified by the user along with their default values.
Please remember to leave a blank space between the parameter and the value.

**Configuration file** (YAML):

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

    # Miscellaneous software
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

    Location of the bcftools executable (e.g., /home/foo/bcftools\_1.11/bcftools).

- **dbnsfpset**

    The set of fields to be taken from dbNSFP database.

    Values: \<all> or \<ega>

- **genome**

    Your reference genome.

    Accepted values: hg19, hg38, and hs37.

    If you used GATKs GRCh37/b37 set it to hg19.

    Not supported: NCBI36/hg18, NCBI35/hg17, NCBI34/hg16, hg15, and older.

- **hg19{clinvar,cosmic,dbnsfp,fasta}**

    Path for each of these files. COSMIC annotations are added but not used (v2.0.0).

- **hg38{clinvar,cosmic,dbnsfp,fasta}**

    Path for each of these files. COSMIC annotations are added but not used (v2.0.0).

- **hs37**

    Path for the reference genome hs37.

- **mem**

    RAM memory for the Java processes (e.g., 8G).

- **mongoXYZ**

    Parameters needed for MongoDB.

- **paneldir**

    A directory where you can store text files (consisting of a column with a list of genes) to be displayed by the BFF Genomic Variations Browser.

- **snpeff**

    Location of the java archive dir (e.g., /home/foo/snpEff/snpEff.jar).

- **snpsift**

    Location of the java archive dir (e.g., /home/foo/snpEff/snpSift.jar).

- **tmpdir**

    Use if you have a preferred tmpdir.

### System requirements

- Ideally a Debian-based distribution (Ubuntu or Mint), but any other (e.g., CentOS, OpenSUSE) should do as well (untested).
- Perl 5 (>= 5.10 core; installed by default in most Linux distributions). Check the version with `perl -v`
- 4GB of RAM (ideally 16GB).
- \>= 1 core (ideally i7 or Xeon).
- At least 200GB HDD.
- bcftools, SnpEff, and MongoDB

The Perl itself does not need a lot of RAM (max load will reach 400MB), but external tools do (e.g., process `mongod` [MongoDB's daemon]).

### Testing the code

I am not using any CPAN modules to perform unit tests. When I modify the code, my "integration tests" are done by comparing to reference files. You can validate the installation using the files included in the [test](https://github.com/mrueda/beacon2-ri-tools/tree/main/test) directory.

