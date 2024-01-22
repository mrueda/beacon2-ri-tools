#!/usr/bin/env bash 
# Date       : 2022-Aug-05
# Version    : 2.0.0
# Author     : Mauricio Moldes (mauricio.moldes@crg.eu)
# Revised by : Manuel Rueda (manuel.rueda@cnag.crg.eu)

share_dir=/usr/share/beacon-ri
tmp_dir=/tmp
ftp_site=ftp://FTPuser:FTPusersPassword@xfer13.crg.eu:221
n_connect=4

################
## Pull external annotation DB 
################

cd $tmp_dir

echo "##### Downloading external files from $ftp_site #####"

aria2c -x 1 -s 1 $ftp_site/beacon2_data.md5 
for i in {1..5}
do
 aria2c -x $n_connect -s $n_connect $ftp_site/beacon2_data.part$i 
done

##########################
## Verifies correct download of external annotation DB
##########################

echo "##### Verifying the integrity of the files #####"

md5sum beacon2_data.part? > my_beacon2_data.md5 
DIFF_MD5=$(cmp -s my_beacon2_data.md5 beacon2_data.md5)
if [ "$DIFF_MD5" != "" ] 
then
 echo "MD5 sum issue"
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

rm $tmp_dir/beacon2_data.tar.gz 
rm $tmp_dir/beacon2_data.md5

#########################
## Set config file 
#########################

echo "##### Fixing paths at <$share_dir/pro/snpEff/snpEff.config> #####"

cd $share_dir/pro/snpEff

sed -i "s|data.dir = ./data/|data.dir = $share_dir/databases/snpeff/v5.0|g" snpEff.config

cd $share_dir/beacon2-ri-tools

echo "##### Fixing paths at <$share_dir/beacon2-ri-tools/config.yaml> #####"

old_dir=/media/mrueda/8TB/Databases
new_dir=$share_dir/databases
for name in genomes snpeff 
do
 sed -i "s|$old_dir/$name|$new_dir/$name|g" config.yaml
done

sed -i -e "s|/pro/NGSutils/snpEff|$share_dir/pro/snpEff|g" \
       -e "s|/pro/NGSutils|$share_dir/pro/NGSutils|g" \
       -e 's|/media/mrueda/8TB/tmp|/tmp|g' \
       -e "s|/home/mrueda/Soft/mongodb-database-tools-ubuntu2004-x86_64-100.5.1/bin|$share_dir/pro/mongodb-database-tools-ubuntu2004-x86_64-100.5.1/bin|g" \
       -e "s|/usr/bin/mongosh|$share_dir/pro/mongosh|g" config.yaml

#######################
## Test deployment 
#######################

echo "##### Running integration test #####"

./beacon vcf -i test/test_1000G.vcf.gz -p test/param.in 

test_result=$( ls -t . | head -1) 

DIFF_DEPLOYMENT=$(diff <(zcat "$test_result"/vcf/genomicVariationsVcf.json.gz | jq 'del(.[]._info)' -S) <(zcat test/beacon_166403275914916/vcf/genomicVariationsVcf.json.gz | jq 'del(.[]._info)' -S) )

if [ "$DIFF_DEPLOYMENT" == "" ] 
then
 echo "Congratulations! <beacon2-ri-tools> are deployed"
fi
