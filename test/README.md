
# Test README

This directory contains data to verify that the transformation of `VCF` to `BFF` functions as expected.

## Data Download (hs37)

**(There is no need to download it again unless you want to test with a different region.)**

The test file included (`test_1000G.vcf.gz`) originates from the 1000 Genomes Project. It was obtained using the following command:

```bash
# tabix -h ftp://ftp-trace.ncbi.nih.gov/1000genomes/ftp/release/20130502/ALL.chr1.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz 1:10000-200000 | bgzip > test_1000G.vcf.gz
```

**Note**: If you encounter an error from `tabix` regarding the `ftp` protocol, try downloading the file locally first:

```bash
# wget ftp://ftp-trace.ncbi.nih.gov/1000genomes/ftp/release/20130502/ALL.chr1.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz
# tabix -p vcf ALL.chr1.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz
# tabix -h ALL.chr1.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz | 1:10000-200000 | bgzip > test_1000G.vcf.gz
```

## Run `beacon`

To test your installation, please execute the command below:
(It should take less than 1 minute to complete.)

```bash
../bin/beacon vcf -i test_1000G.vcf.gz -p param.yaml  # Note that here we used hs37 as the reference genome
```

## Test

Once completed, verify that your file `genomicVariationsVcf.json.gz` matches the provided one:

(Where XXXX is the ID of your job)

```bash
diff <(zcat beacon_XXXX/vcf/genomicVariationsVcf.json.gz | jq 'del(.[]._info)' -S) <(zcat beacon_166403275914916/vcf/genomicVariationsVcf.json.gz | jq 'del(.[]._info)' -S) 
```

In Ubuntu, you can install the tool `jq` with the following command:

```bash
sudo apt-get install jq
```

Cheers!

Manu
