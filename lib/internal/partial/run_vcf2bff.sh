#!/usr/bin/env bash
#
#   Script that generates BFF format from VCF
#
#   Last Modified: Mar/17/2025
#
#   Version taken from $BEACON
#
#   Copyright (C) 2021-2022 Manuel Rueda - CRG
#   Copyright (C) 2023-2025 Manuel Rueda - CNAG (manuel.rueda@cnag.eu)
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

#____WRAPPER_VARIABLES____#

function usage {
    echo "Usage: $0 <input_vcf> [annotation:true|false]"
    exit 1
}

# Check if at least one argument (input VCF) is provided
if [ $# -lt 1 ]; then
    usage
fi

# Load input arguments
INPUT_VCF=$1
# Optional second argument determines whether to run full annotation steps (default is false)
ANNOTATION=${2:-false}
BASE=$(basename "$INPUT_VCF" .vcf.gz)

if [ "$ANNOTATION" == "true" ]; then
    echo "# Running bcftools normalization"
    $BCFTOOLS norm -cs -m -both "$INPUT_VCF" -f "$REF" -Oz -o "$BASE.norm.vcf.gz"
    
    echo "# Running SnpEff annotation"
    $SNPEFF -noStats -i vcf -o vcf "$GENOME" "$BASE.norm.vcf.gz" | $ZIP > "$BASE.norm.ann.vcf.gz"
    
    echo "# Running SnpSift dbNSFP annotation"
    $SNPSIFT dbnsfp -v -db "$DBNSFP" -f #____WRAPPER_FIELDS____# "$BASE.norm.ann.vcf.gz" | $ZIP > "$BASE.norm.ann.dbnsfp.vcf.gz"
    
    echo "# Running SnpSift ClinVar annotation"
    $SNPSIFT annotate "$CLINVAR" -name CLINVAR_ "$BASE.norm.ann.dbnsfp.vcf.gz" | $ZIP > "$BASE.norm.ann.dbnsfp.clinvar.vcf.gz"
    
    echo "# Running SnpSift COSMIC annotation"
    $SNPSIFT annotate "$COSMIC" -name COSMIC_ "$BASE.norm.ann.dbnsfp.clinvar.vcf.gz" | $ZIP > "$BASE.norm.ann.dbnsfp.clinvar.cosmic.vcf.gz"
    
    # Use the fully annotated VCF file as input for vcf2bff
    VCF2BFF_INPUT="$BASE.norm.ann.dbnsfp.clinvar.cosmic.vcf.gz"
else
    # Skip annotation steps and use the original VCF file for conversion
    VCF2BFF_INPUT="$INPUT_VCF"
fi

echo "# Running vcf2bff conversion"
$VCF2BFF -i "$VCF2BFF_INPUT" --project-dir "$PROJECTDIR" --dataset-id "$DATASETID" --genome "$GENOME" -verbose

echo "# Finished OK"

