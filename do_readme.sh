bin/beacon -V | awk '{print $1}' | sed 's/_.*$//' > VERSION

VERSION=$(cat VERSION)

cat <<EOF > README.md
<div align="center">
    <a href="https://github.com/mrueda/beacon2-ri-tools">
        <img src="https://raw.githubusercontent.com/mrueda/beacon2-ri-tools/main/browser/web/img/logo.png" width="200" alt="beacon2-ri-tools">
    </a>
</div>

<div align="center" style="font-family: Consolas, monospace;">
    <h1>beacon2-ri-tools</h1>
</div>

[![Docker build](https://github.com/mrueda/beacon2-ri-tools/actions/workflows/docker-build.yml/badge.svg)](https://github.com/mrueda/beacon2-ri-tools/actions/workflows/docker-build.yml)
[![Documentation Status](https://readthedocs.org/projects/b2ri-documentation/badge/?version=latest)](https://b2ri-documentation.readthedocs.io/en/latest/?badge=latest)
![Maintenance status](https://img.shields.io/badge/maintenance-actively--developed-brightgreen.svg)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Docker Pulls](https://badgen.net/docker/pulls/manuelrueda/beacon2-ri-tools?icon=docker\&label=pulls)](https://hub.docker.com/r/manuelrueda/beacon2-ri-tools/)
[![Docker Pulls EGA-archive](https://badgen.net/docker/pulls/beacon2ri/beacon_reference_implementation?icon=docker\&label=EGA-archive-pulls)](https://hub.docker.com/r/beacon2ri/beacon_reference_implementation/)
![version](https://img.shields.io/badge/version-${VERSION}-blue)

**Documentation**: <a href="https://b2ri-documentation.readthedocs.io/" target="_blank">https://b2ri-documentation.readthedocs.io/</a>

**Docker Hub Image**: <a href="https://hub.docker.com/r/manuelrueda/beacon2-ri-tools/tags" target="_blank">https://hub.docker.com/r/manuelrueda/beacon2-ri-tools/tags</a>

**Actively maintained by the original author**

# TABLE OF CONTENTS
- [Description](#description)
  - [B2RI Diagram](#b2ri-diagram)
  - [Roadmap](#roadmap)
- [Installation](#installation)
  - [Containerized](#containerized-installation-recommended)
  - [Non-Containerized](#non-containerized-installation)
- [Citation](#citation)
  - [Author](#author)
- [License](#license)

# DESCRIPTION

**beacon2-ri-tools** is part of the ELIXIR-Beacon v2 Reference Implementation (B2RI). It provides essential tools for ingesting, validating, and visualizing genomic and phenotypic data.

### Tools Included:
- The [beacon](https://github.com/mrueda/beacon2-ri-tools/tree/main/bin/README.md) script (located at \`bin/beacon\`): Command-line tool for genomic data ingestion and validation.
- A suite of [utilities](https://github.com/mrueda/beacon2-ri-tools/tree/main/utils) aiding in data ingestion.
- The [CINECA_synthetic_cohort_EUROPE_UK1](https://github.com/mrueda/beacon2-ri-tools/tree/main/CINECA_synthetic_cohort_EUROPE_UK1) dataset.

### B2RI Diagram

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

    For \`VCF\`, this will imply adopting VRS nomenclature and maybe moving away from \`LegacyVariation\`. Adding support for Structural variants if present.

    For other entities, make sure that we follow the latest schema in \`bff-validator\`, and the Excel file.

    Update **CINECA** synthetic dataset.

- **Improve Genomic Variations Browser**

    So that it works as a web-server instead of a static web-page.

# INSTALLATION

You can install \`beacon2-ri-tools\` using one of two methods:

### Containerized Installation (Recommended)

Follow the guide [here](docker/README.md) to use Docker for a streamlined setup.

### Non-Containerized Installation

See [here](non-containerized/README.md) for manual installation instructions.

# CITATION

The author requests that any published work that utilizes **B2RI** includes a cite to the the following reference:

Rueda, M, Ariosa R. "Beacon v2 Reference Implementation: a toolkit to enable federated sharing of genomic and phenotypic data". _Bioinformatics_, btac568, https://doi.org/10.1093/bioinformatics/btac568

# AUTHOR

Written by Manuel Rueda, PhD. Info about CNAG can be found at [https://www.cnag.eu](https://www.cnag.eu)

# COPYRIGHT and LICENSE

This repository is copyrighted, (C) 2021-2024 Manuel Rueda. See the LICENSE file included in this distribution.

EOF

pod2markdown bin/beacon > bin/README.md
git add bin/beacon bin/README.md README.md
git add VERSION
