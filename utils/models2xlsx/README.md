# README

**THIS IS SCRIPT HAS TO BE RUN ONLY BY B2RI DEVELOPERS**.

This is the README file for `models2xlsx` utility.

## Motivation 

The idea of this tool is to transform the terms from Beacon v2 Models (stored hierarchically in the form of JSON schemas) to a template that can be later filled out by a user.

We will be extracting the terms from each of the **seven entities** and converting them to **headers**.

## How to run

_NB:_ You need to have the de-referenced Beacon v2 default schemas accessible.

    $ bash defaultSchema2xlsx.sh

### Credits

1. We use `csv2xlsx` (which is part of [Text::CSV_XS]( https://metacpan.org/dist/Text-CSV_XS)) written by H.M.Brand.
