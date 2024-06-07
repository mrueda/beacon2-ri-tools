#!/usr/bin/env bash
#
#   Script that generates BFF format from VCF
#
#   Last Modified: Dec/14/2021
#
#   Version taken from $beacon
#
#   Copyright (C) 2021-2024 Manuel Rueda (manuel.rueda@cnag.eu)
#
#   Credits: Dietmar Fernandez-Orth for creating bcftools/snpEff commands
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, see <https://www.gnu.org/licenses/>.
#
#   If this program helps you in your research, please cite.

set -euo pipefail
export LC_ALL=C
#____VARIABLES____#

function usage {

    USAGE="""
    Usage: $0 <../../input_vcf>
    """
    echo "$USAGE"
    exit 1
}

# Check #arguments
if [ $# -eq 0 ]
 then
  usage
fi

# Load arguments
input_vcf=$1
base=$(basename $input_vcf .vcf.gz)

# Step 1: BCFtools normalization (left-aligning INDELS and split multiallelic to biallelic)
echo "# Running bcftools"
$bcftools norm -cs -m -both $input_vcf -f $ref -Oz -o $base.norm.vcf.gz

# Step 2: SnpEff annotation (w/o stats)
echo "# Running SnpEff"
$snpeff -noStats -i vcf -o vcf $genome $base.norm.vcf.gz | $zip > $base.norm.ann.vcf.gz

# Step 3: SnpSift annotation using dbNSFP (the set of fields is defined with <dbnsfpset> paramater in config)
echo "# Running SnpSift dbNSFP"
$snpsift dbnsfp -v -db $dbnsfp -f #____FIELDS____# $base.norm.ann.vcf.gz | $zip > $base.norm.ann.dbnsfp.vcf.gz

# Step 4: SnpSift annotation using ClinVar (adding ID and INFO fields)
echo "# Running SnpSift ClinVar"
$snpsift annotate $clinvar -name CLINVAR_ $base.norm.ann.dbnsfp.vcf.gz | $zip > $base.norm.ann.dbnsfp.clinvar.vcf.gz

# Step 5: SnpSift annotation using COSMIC (adding ID and INFO fields)
echo "# Running SnpSift COSMIC"
$snpsift annotate $cosmic -name COSMIC_ $base.norm.ann.dbnsfp.clinvar.vcf.gz | $zip > $base.norm.ann.dbnsfp.clinvar.cosmic.vcf.gz

# Step 6: vcf2bff
echo "# Running vcf2bff"
$vcf2bff -i $base.norm.ann.dbnsfp.clinvar.cosmic.vcf.gz --project-dir $projectdir --dataset-id $datasetid --genome $genome -verbose

# All done
echo "# Finished OK"
