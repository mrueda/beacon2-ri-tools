
# hs37 (1000 Genomes Project version of GRCh37)

See the [test directory](../test/README.md).

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

**Note**: If your version of `tabix`accepts using `ftp` protocol:

```bash
# tabix -h  ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000_genomes_project/release/20190312_biallelic_SNV_and_INDEL/ALL.chr22.shapeit2_integrated_snvindels_v2a_27022019.GRCh38.phased.vcf.gz 22:10516173-11016173  | sed 's/^22    /chr22  /' | bgzip > test_1000G_hg38.vcf.gz


## Data subset

Next, we need to convert the GRCh38 file to hg38. This involves adding the prefix 'chr' to '22' to obtain `chr22`. To avoid making a substitution in the header of the VCF, we will index the file with `tabix`:


```bash
tabix -h ALL.chr22.shapeit2_integrated_snvindels_v2a_27022019.GRCh38.phased.vcf.gz 22:10516173-11016173 | sed 's/^22	/chr22	/' | bgzip > test_1000G_hg38.vcf.gz
tabix -p vcf test_1000G_hg38.vcf.gz
```

## Run `beacon`

```bash
../bin/beacon vcf -i test_1000G_hg38.vcf.gz -p param_hg38.yaml  # Note that here we used hg38 as the reference genome
```
