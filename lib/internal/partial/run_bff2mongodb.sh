#!/usr/bin/env bash
#
#   Script that loads BFF data into MongoDB
#
#   Last Modified: Oct/19/2021
#
#   Version taken from $beacon
#
#   Copyright (C) 2021-2022 Manuel Rueda - CRG
#   Copyright (C) 2023-2025 Manuel Rueda - CNAG (manuel.rueda@cnag.eu)
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

    USAGE="""
    Usage: $0
    """
    echo "$USAGE"
    exit 1
}

# Check #arguments
if [ $# -ne 0 ]
 then
  usage
fi

# Load the data into MongoDB
for collection in "${!collections[@]}"
do
 echo "Loading collection...$collection"
 $MONGOIMPORT --jsonArray --uri "$MONGODBURI" --file ${collections[$collection]} --collection $collection || echo "Could not load <${collections[$collection]}> for <$collection>"
 echo "Indexing collection...$collection"
 $MONGOSH "$MONGODBURI" << EOF
disableTelemetry()
/* Single field indexes */
db.$collection.createIndex( {"\$**": 1}, {name: "single_field_$collection"} )
/* Text indexes */
db.$collection.createIndex( {"\$**": "text"}, {name: "text_$collection"} )
quit()
EOF
done
#__WRAPPER_GENOMIC_VARIATIONS_VARIABLES__#

# All done
echo "# Finished OK"
