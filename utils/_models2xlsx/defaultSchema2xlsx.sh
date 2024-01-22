#!/usr/bin/env bash
#
#   Script to convert Beacon v2 Models to XLSX (with sheets)
#
#   Last Modified: Apr/04/2021
#
#   Version 2.0.0
#
#   Copyright (C) 2021-2022 Manuel Rueda (manuel.rueda@crg.eu)
#
#   Accessory script 'csv2xlsx' is part of Text::CSV_XS
#   https://metacpan.org/dist/Text-CSV_XS
#   https://github.com/Tux/Text-CSV_XS/tree/master/examples
#   Copyright H.M.Brand 2007-2021
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

set -eu
in_dir=/media/mrueda/4TB/CRG_EGA/Project_Beacon/readthedocs/beacon-v2/bin/deref_schemas
json=defaultSchema.json
parser=./parse_defaultSchema.pl
csv2xlsx=./csv2xlsx
out=Beacon-v2-Models_template.xlsx

cat<<EOT
=========================
Transforming JSON to XLSX
=========================

EOT

mkdir -p data
for schema in $(ls -1 $in_dir | grep -v obj) 
do
 echo "Extracting the header from $schema ..."
 $parser $in_dir/$schema/$json >  data/$schema.csv
done
$csv2xlsx data/*csv -o $out
