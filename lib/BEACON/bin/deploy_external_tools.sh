#!/usr/bin/env bash 
#########################################
# Script Name: deploy_external_tools.sh
# Description: Manages annotation files for Beacon-RI tools
#
# Author: Mauricio Moldes (mauricio.moldes@crg.eu)
# Revised by: Manuel Rueda (manuel.rueda@cnag.eu)
# Date: 2022-Aug-05
# Version: 2.0.0
# Last Modified: 2024-Dec-02
#########################################

set -euo pipefail

share_dir=/usr/share/beacon-ri
tmp_dir=/tmp
ftp_site=ftp://FTPuser:FTPusersPassword@xfer13.crg.eu:221
n_connect=4

################
## Pull external annotation DB 
################

cd $tmp_dir

echo "##### Downloading external files from $ftp_site #####"

# Download the MD5 checksum file
if ! aria2c -x 1 -s 1 "$ftp_site/beacon2_data.md5"; then
  echo "Error: Failed to download beacon2_data.md5"
  exit 1
fi

# Download the data parts in a loop
for i in $(seq 1 5); do
  retries=3
  while ! aria2c -x "$n_connect" -s "$n_connect" "$ftp_site/beacon2_data.part$i" && ((retries-- > 0)); do
    echo "Retrying download for beacon2_data.part$i..."
  done
  if ((retries == 0)); then
    echo "Error: Failed to download beacon2_data.part$i after multiple attempts"
    exit 1
  fi
done

##########################
## Verifies correct download of external annotation DB
##########################

echo "##### Verifying the integrity of the files #####"

md5sum beacon2_data.part? > my_beacon2_data.md5 
if ! cmp -s my_beacon2_data.md5 beacon2_data.md5; then
  echo "MD5 sum issue: Checksums do not match"
  exit 1
else
  echo "MD5 sum verification passed"
fi

##########################
## Untaring of files
##########################

echo "##### Untaring files into <$share_dir> #####"

cat beacon2_data.part? > beacon2_data.tar.gz 
rm beacon2_data.part? 
tar -xvf beacon2_data.tar.gz --directory $share_dir/

#########################
## Soft link  GRCh38 hg38
#########################

echo "##### Creating symbolic links #####"

cd $share_dir/databases/snpeff/v5.0 && ln -s GRCh38.99 hg38 

#########################
## Remove auxiliar files
#########################

echo "##### Deleting auxiliary files #####"

rm $tmp_dir/beacon2_data.tar.gz $tmp_dir/beacon2_data.md5

#########################
## Set config file 
#########################

echo "##### Fixing paths at <$share_dir/pro/snpEff/snpEff.config> #####"

sed -i "s|data.dir = ./data/|data.dir = $share_dir/databases/snpeff/v5.0|g" $share_dir/pro/snpEff/snpEff.config

#######################
## Test Deployment
#######################

cd $share_dir/beacon2-ri-tools

echo "##### Running integration test #####"

# Ensure the test file and binary exist
if [[ ! -x bin/beacon ]]; then
  echo "Error: beacon executable not found or not executable"
  exit 1
fi

if [[ ! -f test/test_1000G.vcf.gz || ! -f test/param.yaml ]]; then
  echo "Error: Required test files (test_1000G.vcf.gz or param.yaml) are missing"
  exit 1
fi

# Run the test command
bin/beacon vcf -i test/test_1000G.vcf.gz -p test/param.yaml

# Identify the latest result directory
test_result=$(ls -td -- */ | head -n 1)

if [[ -z "$test_result" ]]; then
  echo "Error: No test result directory created"
  exit 1
fi

# Compare the outputs
DIFF_DEPLOYMENT=$(diff <(zcat "$test_result/vcf/genomicVariationsVcf.json.gz" | jq 'del(.[]._info)' -S) \
                       <(zcat test/beacon_166403275914916/vcf/genomicVariationsVcf.json.gz | jq 'del(.[]._info)' -S))

if [[ -z "$DIFF_DEPLOYMENT" ]]; then
  echo "Congratulations! <beacon2-ri-tools> are deployed"
else
  echo "Error: Deployment test failed. Differences detected in test output"
  exit 1
fi
