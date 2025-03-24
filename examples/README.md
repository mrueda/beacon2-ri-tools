# hs37 (1000 Genomes Project version of GRCh37)

See the [test directory](https://github.com/CNAG-Biomedical-Informatics/beacon2-cbi-tools/tree/main/test).

# hg38 (GRCh38)

## Data Download 

We download the data using `wget` since we could not use `tabix` directly:

```bash
wget ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000_genomes_project/release/20190312_biallelic_SNV_and_INDEL/ALL.chr22.shapeit2_integrated_snvindels_v2a_27022019.GRCh38.phased.vcf.gz
```

Now, we index the VCF with `tabix`:

```bash
tabix -p vcf ALL.chr22.shapeit2_integrated_snvindels_v2a_27022019.GRCh38.phased.vcf.gz
```

**Note**: If your version of `tabix` accepts using `ftp` protocol:

```bash
#tabix -h ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000_genomes_project/release/20190312_biallelic_SNV_and_INDEL/ALL.chr22.shapeit2_integrated_snvindels_v2a_27022019.GRCh38.phased.vcf.gz 22:10516173-11016173  | sed 's/^22    /chr22  /' | bgzip > test_1000G_hg38.vcf.gz
```

## Data subset

Next, we need to convert the GRCh38 file to hg38. This involves adding the prefix 'chr' to '22' to obtain `chr22`. 

```bash
tabix -h ALL.chr22.shapeit2_integrated_snvindels_v2a_27022019.GRCh38.phased.vcf.gz 22:10516173-11016173 | sed -e 's/##contig=<ID=22>/##contig=<ID=chr22>/' -e 's/^22\t/chr22\t/' | bgzip > test_1000G_hg38.vcf.gz
```

## Run `bff-tools`

The simplest task is to convert a `VCF` file to the `BFF` format. The resulting files will be located in the `beacon_*/vcf/` directory.

```bash
../bin/bff-tools vcf -i test_1000G_hg38.vcf.gz -p param_hg38.yaml
# Here we're using 'hg38' as the reference genome.
```

### Alternative `bff-tools` modes

If your `mongo` container is set up and running, you can convert the `VCF` and load the data into MongoDB in a single step using the `full` mode:

```bash
../bin/bff-tools full -i test_1000G_hg38.vcf.gz -p param_hg38.yaml
# This runs both 'vcf' and 'load' steps together.
```

The result of the MongoDB import will be located in the `beacon_*/mongodb/` directory.

### Loading other Beacon v2 Model entities

To import other Beacon v2 Model entities into MongoDB (without converting VCFs), use the `load` mode with a YAML file:

```bash
../bin/bff-tools load -p load.yaml
```
