[![Docker build](https://github.com/mrueda/beacon2-ri-tools/actions/workflows/docker-build.yml/badge.svg)](https://github.com/mrueda/beacon2-ri-tools/actions/workflows/docker-build.yml)
[![Documentation Status](https://readthedocs.org/projects/b2ri-documentation/badge/?version=latest)](https://b2ri-documentation.readthedocs.io/en/latest/?badge=latest)
![Maintenance status](https://img.shields.io/badge/maintenance-actively--developed-brightgreen.svg)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Docker Pulls](https://badgen.net/docker/pulls/manuelrueda/beacon2-ri-tools?icon=docker\&label=pulls)](https://hub.docker.com/r/manuelrueda/beacon2-ri-tools/)
[![Docker Pulls EGA-archive](https://badgen.net/docker/pulls/beacon2ri/beacon_reference_implementation?icon=docker\&label=EGA-archive-pulls)](https://hub.docker.com/r/beacon2ri/beacon_reference_implementation/)
![version](https://img.shields.io/badge/version-2.0.4-blue)

**Documentation**: <a href="https://b2ri-documentation.readthedocs.io/" target="_blank">https://b2ri-documentation.readthedocs.io/</a>

**CLI Source Code**: <a href="https://github.com/mrueda/beacon2-ri-tools" target="_blank">https://github.com/mrueda/beacon2-ri-tools</a>

**Docker Hub Image**: <a href="https://hub.docker.com/r/manuelrueda/beacon2-ri-tools/tags" target="_blank">https://hub.docker.com/r/manuelrueda/beacon2-ri-tools/tags</a>

**Actively maintained by the original author**

# DESCRIPTION

**beacon2-ri-tools** repository, part of the ELIXIR-Beacon v2 Reference Implementation (B2RI), includes:

- The [beacon](https://github.com/mrueda/beacon2-ri-tools/tree/main/bin/README.md) script
- A suite of [utilities](https://github.com/mrueda/beacon2-ri-tools/tree/main/utils) aiding in data ingestion
- The [CINECA_synthetic_cohort_EUROPE_UK1](https://github.com/mrueda/beacon2-ri-tools/tree/main/CINECA_synthetic_cohort_EUROPE_UK1) dataset

### B2RI diagram

                * Beacon v2 Reference Implementation *

                    ___________
              XLSX  |          |
               or   | Metadata | (incl. Phenotypic data)
              JSON  |__________|
                         |
                         |
                         | Validation (bff-validator)
                         |
     _________       ____v____        __________         ______
     |       |       |       |       |          |        |     | <---- Request
     |  VCF  | ----> |  BFF  | ----> | Database | <----> | API |
     |_______|       |_ _____|       |__________|        |_____| ----> Response
                         |             MongoDB
              beacon     |    beacon
                         |
                         |
                      Optional
                         |
                   ______v_______
                   |            |
                   | BFF        |
                   | Genomic    | Visualization
                   | Variations |
                   | Browser    |
                   |____________|

    ------------------------------------------------|||------------------------
    beacon2-ri-tools                                             beacon2-ri-api

## ROADMAP 

**Latest Update: Nov-2024**

We know that this repository has been downloaded and used in many Beacon v2 implementations, so our plan is to keep supporting it and improving it. These are our plans:

- **Implement Beacon 2.1 changes**

    For `VCF`, this will imply adopting VRS nomenclature and maybe moving away from `LegacyVariation`. Adding support for Structural variants if present.

    For other entities, make sure that we follow the latest schema in `bff-validator`, and the Excel file.

    Update **CINECA** synthetic dataset.

- **Improve Genomic Variations Browser**

    So that it works as a web-server instead of a static web-page.

# INSTALLATION

We provide two installation options for `beacon2-ri-tools`, containerized **(recommended)** and non-containerized.

## Containerized

See information [here](docker/README.md).

## Non-Containerized

See information [here](non-containerized/README.md).

# CITATION

The author requests that any published work that utilizes **B2RI** includes a cite to the the following reference:

Rueda, M, Ariosa R. "Beacon v2 Reference Implementation: a toolkit to enable federated sharing of genomic and phenotypic data". _Bioinformatics_, btac568, https://doi.org/10.1093/bioinformatics/btac568

# AUTHOR

Written by Manuel Rueda, PhD. Info about CNAG can be found at [https://www.cnag.eu](https://www.cnag.eu)

Credits:

    * Sabela De La Torre (SDLT) created a Bash script for Beacon v1 to parse vcf files L<https://github.com/ga4gh-beacon/beacon-elixir>.
    * Toshiaki Katayamai re-implemented the Beacon v1 script in Ruby.
    * Later Dietmar Fernandez-Orth (DFO) modified the Ruby for Beacon v2 L<https://github.com/ktym/vcftobeacon and added post-processing with R, from which I borrowed ideas to implement vcf2bff.pl.
    * DFO for usability suggestions and for creating bcftools/snpEff commands.
    * Roberto Ariosa for help with MongoDB implementation.
    * Mauricio Moldes helped with the containerization.

# COPYRIGHT and LICENSE

This repository is copyrighted, (C) 2021-2024 Manuel Rueda. See the LICENSE file included in this distribution.

