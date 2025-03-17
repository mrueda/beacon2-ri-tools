#!/usr/bin/env bash
#
#   Script that generates BFF format from VCF
#
#   Last Modified: Mar/17/2025
#
#   Version taken from $beacon
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
# All necessary variables (e.g., bcftools, ref, snpeff, zip, snpsift, clinvar, cosmic,
# vcf2bff, projectdir, datasetid, genome, etc.) are expected to be defined
# by the wrapper script that calls this script.

function usage {
    echo "Usage: $0 <input_vcf> [annotation:true|false]"
    exit 1
}

# Check if at least one argument (input VCF) is provided
if [ $# -lt 1 ]; then
    usage
fi

# Load input arguments
input_vcf=$1
# Optional second argument determines whether to run full annotation steps (default is false)
annotation=${2:-false}
base=$(basename "$input_vcf" .vcf.gz)

if [ "$annotation" == "true" ]; then
    echo "# Running bcftools normalization"
    $bcftools norm -cs -m -both "$input_vcf" -f "$ref" -Oz -o "$base.norm.vcf.gz"
    
    echo "# Running SnpEff annotation"
    $snpeff -noStats -i vcf -o vcf "$genome" "$base.norm.vcf.gz" | $zip > "$base.norm.ann.vcf.gz"
    
    echo "# Running SnpSift dbNSFP annotation"
    $snpsift dbnsfp -v -db "$dbnsfp" -f #____WRAPPER_FIELDS____# "$base.norm.ann.vcf.gz" | $zip > "$base.norm.ann.dbnsfp.vcf.gz"
    
    echo "# Running SnpSift ClinVar annotation"
    $snpsift annotate "$clinvar" -name CLINVAR_ "$base.norm.ann.dbnsfp.vcf.gz" | $zip > "$base.norm.ann.dbnsfp.clinvar.vcf.gz"
    
    echo "# Running SnpSift COSMIC annotation"
    $snpsift annotate "$cosmic" -name COSMIC_ "$base.norm.ann.dbnsfp.clinvar.vcf.gz" | $zip > "$base.norm.ann.dbnsfp.clinvar.cosmic.vcf.gz"
    
    # Use the fully annotated VCF file as input for vcf2bff
    vcf2bff_input="$base.norm.ann.dbnsfp.clinvar.cosmic.vcf.gz"
else
    # Skip annotation steps and use the original VCF file for conversion
    vcf2bff_input="$input_vcf"
fi

echo "# Running vcf2bff conversion"
$vcf2bff -i "$vcf2bff_input" --project-dir "$projectdir" --dataset-id "$datasetid" --genome "$genome" -verbose

echo "# Finished OK"
