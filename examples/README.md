# hs37 (1000 Genomes Project version of GRCh37)

See [test directory](../test/README.md).

# hg38 (GRCh38)

```bash
wget ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/1000_genomes_project/release/20190312_biallelic_SNV_and_INDEL/ALL.chr22.shapeit2_integrated_snvindels_v2a_27022019.GRCh38.phased.vcf.gz
tabix -p vcf ALL.chr22.shapeit2_integrated_snvindels_v2a_27022019.GRCh38.phased.vcf.gz
tabix -h ALL.chr22.shapeit2_integrated_snvindels_v2a_27022019.GRCh38.phased.vcf.gz 22:10516173-11016173 | sed 's/^22\t/chr22\t/' | bgzip > test_1000G_hg38.vcf.gz
tabix -p vcf test_1000G_hg38.vcf.gz
```

To run:

```bash
../bin/beacon vcf -i test_1000G_hg38.vcf.gz -p param_hg38.yaml  # Note that here we used hg38 as a reference genome
```

