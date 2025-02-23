# Test README

This directory contains data to test that the transformation of `VCF` to `BFF` works as it should.

## Data Download (hs37)

The test file included (`test_1000G.vcf.gz`) comes from the 1000 Genomes Project. It was obtained using the following command:
(no need to download again unless you want to try with a different region)

```bash
# tabix -h ftp://ftp-trace.ncbi.nih.gov/1000genomes/ftp/release/20130502/ALL.chr1.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz 1:10000-200000 | bgzip > test_1000G.vcf.gz
```

## Run `beacon`

To test your installation please execute the command below:
(It will take < 1 min to finish) 

```bash
../bin/beacon vcf -i test_1000G.vcf.gz -p param.yaml  # Note that here we used hs37 as a reference genome
```

## Test

Once done, check that your file `genomicVariationsVcf.json.gz` and the provided one match:

(where XXXX is the id of your job)

```bash
diff <(zcat beacon_XXXX/vcf/genomicVariationsVcf.json.gz | jq 'del(.[]._info)' -S) <(zcat beacon_166403275914916/vcf/genomicVariationsVcf.json.gz | jq 'del(.[]._info)' -S) 
```

In Ubuntu, you can install the tool `jq` wil the command below:

```bash
sudo apt-get install jq
```

Cheers!

Manu
