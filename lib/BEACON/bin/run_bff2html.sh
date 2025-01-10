#!/usr/bin/env bash
#
#   Script that generates HTML format from BFF
#
#   Last Modified: Dec/14/2021
#
#   Version taken from $beacon
#
#   Copyright (C) 2021-2025 Manuel Rueda (manuel.rueda@cnag.eu)
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
#____VARIABLES_____

function usage {

    USAGE="""
    Usage: $0 <../vcf/genomicVariationsVcf.json.gz> <id>
    """
    echo "$USAGE"
    exit 1
}

# Check #arguments
if [ $# -le 1 ]
 then
  usage
fi

# Load arguments
input_bff=$1
id=$2

# Step 1: Parse BFF according to gene panels
echo "# Running bff2json"
pattern='HIGH' # it only appears in field 'Annotation Impact', otherwise use awk with #col (see below)
for panel in $panel_dir/*.lst
do
 base=$(basename $panel .lst)
 # NB: 
 zgrep -F -w $pattern $input_bff | grep -F -w -f $panel > $id.$base.$pattern.json  || echo "Nothing found for $base"
 $bff2json -i $id.$base.$pattern.json -f json | jq -s . >  $base.json              || echo "Could not run $bff2json -f json for $base"  # jq needed
 $bff2json -i $id.$base.$pattern.json -f json4html      >  $base.mod.json          || echo "Could not run $bff2json -f json4html for $base"
done

# Step 2: Create HTML for JSON
echo "# Running json2html"
ln -s $web_dir web # symbolic link for css, etc.
$json2html --id $id --web-dir web --panel-dir $panel_dir > $id.html


cat <<EOF > README.txt
# To visualize <$id.html>

# 1. Run Python’s built-in HTTP server
python3 -m http.server 8000 --bind 0.0.0.0

# 2. Open a browser at http://0.0.0.0:8000/

# 3. Load <$id.html>
EOF

# All done
echo "# Finished OK"
