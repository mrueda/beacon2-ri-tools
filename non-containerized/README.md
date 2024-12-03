# INSTALLATION

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

The data ingestion tools need **external software** to function:

* **BCFtools** (version 1.15.1)
* **SnpEff** + databases (version 5.0)
* **MongoDB**

!!! Important
    Even if you have the **external tools** already in your system, for the sake of consistency of versions, we recommend downloading them from our servers.

We will download _BCFtools_, _SnpEff_ and _MongoDB_ utilities from a public `ftp` server (`ftp://xfer13.crg.eu`) located at CRG. We will use `wget` to get the five parts (~65G total). Each part should take around 20 min to download:

    wget ftp://FTPuser:FTPusersPassword@xfer13.crg.eu:221/beacon2_data.md5
    wget ftp://FTPuser:FTPusersPassword@xfer13.crg.eu:221/beacon2_data.part1
    wget ftp://FTPuser:FTPusersPassword@xfer13.crg.eu:221/beacon2_data.part2
    wget ftp://FTPuser:FTPusersPassword@xfer13.crg.eu:221/beacon2_data.part3
    wget ftp://FTPuser:FTPusersPassword@xfer13.crg.eu:221/beacon2_data.part4
    wget ftp://FTPuser:FTPusersPassword@xfer13.crg.eu:221/beacon2_data.part5

Once you have downloaded the 5 parts and the checksum file (\*.md5) please check that they are complete:

    md5sum beacon2_data.part? > my_beacon2_data.md5
    diff my_beacon2_data.md5 beacon2_data.md5

Now join the 5 parts by typing (note that momentarily we'll be using ~128G):

    cat beacon2_data.part? > beacon2_data.tar.gz
    rm beacon2_data.part?

OK, everything ready to untar the file:

``` bash
tar -xvf beacon2_data.tar.gz
cd snpeff/v5.0 ; ln -s GRCh38.99 hg38 # In case the symbolic link does not exist already
```

*NB*: Feel free now to erase ```beacon2_data.tar.gz``` if needed.

Great! now we recommend moving the directories to your favourite location and keep the path. We will be using the paths to **set up** some variables for **SnpEff** and for **beacon** configuration files.

*NB*: SnpEff runs with `java` which you may need to install separately. See how [here](https://ubuntu.com/tutorials/install-jre).

For **SnpEff**:

Use the path where you have left the databases and use it to change ```data.dir``` variable in ```snpEff.config``` file (located in SnpEff installation folder).
For instance, in my case:

```
#data.dir = ./data/

data.dir = /media/mrueda/4TB/Databases/snpeff/v5.0/
```

And finally....

For **Beacon**:

Open the file ```config.yaml``` (inside ```beacon_X.X.X``` dir installation) and change the paths to the files/exes according to your new locations. Note that `SnpSift` is part of `SnpEff` main distribution.

You can start transforming your data to BFF and loading it to the database following the [Data beaconization tutorial](https://b2ri-documentation.readthedocs.io/en/latest/tutorial-data-beaconization/).

That's it!

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

### MongoDB installation

We're going to install it by using [docker-compose](https://docs.docker.com/compose). You need to have `docker` and `docker-compose` installed. `docker-compose` enables defining and running multi-container Docker applications.

!!! Danger "About Docker"
    It's out of the scope of this documentation to explain how to install `docker` engine and `docker-compose`.
    Please take a look to Docker [documentation](https://docs.docker.com/engine/install) if you need help with the installation.

First you need to create a file named ```docker-compose.yml``` with these contents:

```
version: '3.1'

services:
  mongo:
    image: mongo
    hostname: mongo
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: example
    networks:
      -  my-app-network

  mongo-express:
    image: mongo-express
    restart: always
    ports:
      - "8081:8081"
    environment:
      ME_CONFIG_MONGODB_ADMINUSERNAME: root
      ME_CONFIG_MONGODB_ADMINPASSWORD: example
      ME_CONFIG_MONGODB_URL: mongodb://root:example@mongo:27017/
    networks:
      -  my-app-network
```

And then run:

    docker network create my-app-network
    docker-compose up -d

Once complete you should have two Docker processes: ```mongo``` and ```mongo-express```. You can check this by typing:

    docker ps -a

**Mongo Express** is an [open source](https://github.com/mongo-express/mongo-express) lightweight web-based administrative interface deployed to manage MongoDB databases interactively. You can access `mongo-express` at `http://localhost:8081`.

### Testing the code

I am not using any CPAN modules to perform unit tests. When I modify the code, my "integration tests" are done by comparing to reference files. You can validate the installation using the files included in the [test](https://github.com/mrueda/beacon2-ri-tools/tree/main/test) directory.

### Common errors: Symptoms and treatment

  * Perl:
          * Compilation errors:
            - Error: Unknown PerlIO layer "gzip" at (eval 10) line XXX
              Solution: cpanm --sudo PerlIO::gzip
                           ... or ...
                    sudo apt-get install libperlio-gzip-perl

## References

1. BCFtools
    Danecek P, Bonfield JK, et al. Twelve years of SAMtools and BCFtools. Gigascience (2021) 10(2):giab008 [link](https://pubmed.ncbi.nlm.nih.gov/33590861)

2.  SnpEff
    "A program for annotating and predicting the effects of single nucleotide polymorphisms, SnpEff: SNPs in the genome of Drosophila melanogaster strain w1118; iso-2; iso-3.", Cingolani P, Platts A, Wang le L, Coon M, Nguyen T, Wang L, Land SJ, Lu X, Ruden DM. Fly (Austin). 2012 Apr-Jun;6(2):80-92. PMID: 22728672.

3. SnpSift
    "Using Drosophila melanogaster as a model for genotoxic chemical mutational studies with a new program, SnpSift", Cingolani, P., et. al., Frontiers in Genetics, 3, 2012.

4.  dbNSFP v4
    1. Liu X, Jian X, and Boerwinkle E. 2011. dbNSFP: a lightweight database of human non-synonymous SNPs and their functional predictions. Human Mutation. 32:894-899.
    2. Liu X, Jian X, and Boerwinkle E. 2013. dbNSFP v2.0: A Database of Human Non-synonymous SNVs and Their Functional Predictions and Annotations. Human Mutation. 34:E2393-E2402.
    3. Liu X, Wu C, Li C, and Boerwinkle E. 2016. dbNSFP v3.0: A One-Stop Database of Functional Predictions and Annotations for Human Non-synonymous and Splice Site SNVs. Human Mutation. 37:235-241.
    4. Liu X, Li C, Mou C, Dong Y, and Tu Y. 2020. dbNSFP v4: a comprehensive database of transcript-specific functional predictions and annotations for human nonsynonymous and splice-site SNVs. Genome Medicine. 12:103.
