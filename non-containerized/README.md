# Non-containerized installation

## Downloading Required Databases and Software

First, we need to download the necessary databases and software. Unlike `beacon-cbi-tools`, where the data was inside the container, we now store the data externally. This improves data persistence and allows software updates without needing to re-download everything.

### Step 1: Download Required Files

Navigate to a directory with at least **150GB** of available space and run:

```bash
wget https://raw.githubusercontent.com/mrueda/beacon2-cbi-tools/main/scripts/01_download_external_data.py
```

Then execute the script:

```bash
python3 01_download_external_data.py
```

> **Note:** Google Drive can sometimes restrict downloads. If you encounter an error, use the provided error URL in a browser to retrieve the file manually.

### Step 2: Verify Download Integrity

Run a checksum to ensure the files were not corrupted:

```bash
md5sum -c data.tar.gz.md5
```

### Step 3: Reassemble Split Files

The downloaded data is split into parts. Reassemble it into a single tar archive (**~130GB required**):

```bash
cat data.tar.gz.part-?? > data.tar.gz
```

Once the files are successfully merged, delete the split parts to free up space:

```bash
rm data.tar.gz.part-??
```

### Step 4: Extract Data

Extract the tar archive:

```bash
tar -xzvf data.tar.gz
```
## Download from GitHub

First, we need to install a few system components:

```bash
sudo apt install libbz2-dev zlib1g-dev libncurses5-dev libncursesw5-dev liblzma-dev libcurl4-openssl-dev libssl-dev mongodb-clients cpanminus python3-pip perl-doc default-jre
```

Use `git clone` to get the latest (stable) version:

```bash
git clone https://github.com/mrueda/beacon2-cbi-tools.git
cd beacon2-cbi-tools
```

`beacon` is a Perl script (no compilation required) designed to run on the Linux command line. Internally, it acts as a wrapper that submits multiple pipelines through customizable Bash scripts (see an example [here](https://github.com/mrueda/beacon2-cbi-tools/blob/main/lib/BEACON/bin/run_vcf2bff.sh)). While Perl and Bash are pre-installed on most Linux systems, a few additional dependencies must be installed separately.

We use `cpanm` to install the CPAN modules. We'll install the dependencies at `~/perl5`:

```bash
cpanm --local-lib=~/perl5 local::lib && eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
cpanm --notest --installdeps .
```

To ensure Perl recognizes your local modules every time you start a new terminal, run:

```bash
echo 'eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)' >> ~/.bashrc
```

We'll also need a few Python 3 modules:

```bash
pip install -r requirements.txt
```

## System requirements

- Ideally a Debian-based distribution (Ubuntu or Mint), but any other (e.g., CentOS, OpenSUSE) should do as well (untested).
- Perl 5 (>= 5.10 core; installed by default in most Linux distributions). Check the version with `perl -v`
- 4GB of RAM (ideally 16GB).
- \>= 1 core (ideally i7 or Xeon).
- At least 200GB HDD.

The Perl itself does not need a lot of RAM (max load will reach 400MB), but external tools do (e.g., process `mongod` [MongoDB's daemon]).

## Testing the code

The "integration tests" are done by comparing to reference files. You can validate the installation using the files included in the [test](https://github.com/mrueda/beacon2-cbi-tools/tree/main/test) directory.

You may wanna install `jq` for running tests.

```bash
sudo apt install jq
```

### Common errors: Symptoms and treatment

* Perl errors:
    - Error: Unknown PerlIO layer "gzip" at (eval 10) line XXX

      Solution: 

      `cpanm PerlIO::gzip`

         ... or ...

      `sudo apt install libperlio-gzip-perl`

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
