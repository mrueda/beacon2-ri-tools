
<h2> Under Maintenance until March 24</h1>
<div align="center">
    <a href="https://github.com/CNAG-Biomedical-Informatics/beacon2-cbi-tools">
        <img src="https://raw.githubusercontent.com/CNAG-Biomedical-Informatics/beacon2-cbi-tools/main/docs/img/logo.png" width="200" alt="beacon2-cbi-tools">
    </a>
</div>

<div align="center" style="font-family: Consolas, monospace;">
    <h1>beacon2-cbi-tools</h1>
</div>

[![Docker build](https://github.com/CNAG-Biomedical-Informatics/beacon2-cbi-tools/actions/workflows/docker-build.yml/badge.svg)](https://github.com/CNAG-Biomedical-Informatics/beacon2-cbi-tools/actions/workflows/docker-build.yml)
[![Documentation Status](https://readthedocs.org/projects/b2ri-documentation/badge/?version=latest)](https://b2ri-documentation.readthedocs.io/en/latest/?badge=latest)
![Maintenance status](https://img.shields.io/badge/maintenance-actively--developed-brightgreen.svg)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Docker Pulls](https://badgen.net/docker/pulls/manuelrueda/beacon2-ri-tools?icon=docker&label=beacon2-ri-tools-pulls)](https://hub.docker.com/r/manuelrueda/beacon2-ri-tools/)
[![Docker Pulls EGA-archive](https://badgen.net/docker/pulls/beacon2ri/beacon_reference_implementation?icon=docker&label=EGA-archive-pulls)](https://hub.docker.com/r/beacon2ri/beacon_reference_implementation/)
![version](https://img.shields.io/badge/version-2.0.8-blue)

---

**Legacy B2RI Documentation**: <a href="https://b2ri-documentation.readthedocs.io/" target="_blank">https://b2ri-documentation.readthedocs.io/</a>

**Docker Hub Image**: <a href="https://hub.docker.com/r/manuelrueda/beacon2-cbi-tools/tags" target="_blank">https://hub.docker.com/r/manuelrueda/beacon2-cbi-tools/tags</a>

---

> **Note:** This repository was formerly known as **beacon2-ri-tools** (Beacon v2 Reference Implementation). It has been renamed to **beacon2-cbi-tools (CNAG Biomedical Informatics)** to better reflect its identity under CNAG. Development continues actively with full support for converting VCF to BFF and loading BFF data into MongoDB.

**Actively maintained by CNAG Biomedical Informatics**

# Table of contents
- [Description](#description)
  - [System Diagram](#system-diagram)
  - [Roadmap](#roadmap)
- [Installation](#installation)
  - [Containerized](#containerized-installation-recommended)
  - [Non-Containerized](#non-containerized-installation)
- [Citation](#citation)
  - [Author](#author)
- [License](#copyright-and-license)

# DESCRIPTION

**beacon2-cbi-tools** is a suite of tools originally developed as part of the ELIXIR-Beacon v2 Reference Implementation, now continuing under CNAG Biomedical Informatics. It provides essential functionalities for converting VCF data into BFF format and for loading BFF data (including metadata and genomic variations) into a MongoDB instance.

### Tools Included:
- **[Beacon Script](https://github.com/CNAG-Biomedical-Informatics/beacon2-cbi-tools/tree/main/bin/README.md)** (`bin/beacon`): A command-line tool for converting VCF data into BFF format. It also supports inserting the resulting BFF data into a MongoDB instance. The tool offers three modes:
  - **vcf**: Convert a VCF.gz file to BFF.
  - **mongodb**: Insert BFF data into MongoDB.
  - **full**: Perform both conversion and insertion.
- **[Utility Suite](utils/README.md)**: A collection of support tools to aid in data ingestion. Key among them:
  - **[BFF Validator](https://github.com/CNAG-Biomedical-Informatics/beacon2-cbi-tools/tree/main/utils/bff_validator)**: Includes an Excel template for converting your metadata (including phenotypic and clinical data) into Beacon v2 models, along with a validator for verifying and serializing the data into BFF format.
  - **[BFF Browser](https://github.com/CNAG-Biomedical-Informatics/beacon2-cbi-tools/tree/main/utils/bff_browser)**: A web application for interactive visualization of BFF data, particularly `genomicVariations` and `individuals`.
  - **[BFF Portal](https://github.com/CNAG-Biomedical-Informatics/beacon2-cbi-tools/tree/main/utils/bff_portal)**: A simple API and web application to query BFF data via MongoDB.

- **[CINECA Synthetic Cohort - EUROPE_UK1](https://github.com/CNAG-Biomedical-Informatics/beacon2-cbi-tools/tree/main/CINECA_synthetic_cohort_EUROPE_UK1)**: A synthetic dataset for testing and demonstration purposes.

### System Diagram

                * Beacon v2 - CBI Tools *

                    ___________
              XLSX  |          |
               or   | Metadata | (incl. Phenotypic data)
              JSON  |__________|
                         |
                         |
                         | Validation (utils/bff-validator)
                         |
     _________       ____v____        __________         ______
     |       |       |       |       |          |        |     | <---- Request
     |  VCF  | ----> |  BFF  | ----> | Database | <----> | API |
     |_______|       |_ _____|       |__________|        |_____| ----> Response
                         |             MongoDB
              beacon     |    beacon
                         |
                         |
                      Optional (utils)
                         |
                    _____v_____
                    |         |
                    |   BFF   |
                    | Browser | Visualization
                    |  (beta) |
                    |_________|

    ------------------------------------------------|||------------------------
    beacon2-cbi-tools                                             beacon2-ri-api
                                                                  beacon2-pi-api

## Roadmap 

**Latest Update: Mar-2025**

This repository has been widely adopted in Beacon v2 implementations and is also used internally at CNAG. As a result, we plan to continue its development. Some of our upcoming plans include:

- **Implement Beacon 2.x specification changes**

    - For VCF: Adopt VRS nomenclature and transition away from LegacyVariation. Support for structural variants may be added.
    - For other entities: Align with the latest schema used in the BFF Validator and the Excel metadata template.
    - Update the **CINECA Synthetic Cohort** dataset.

# INSTALLATION

You can install **beacon2-cbi-tools** using one of two methods:

### Containerized Installation (Recommended)

Follow the guide [here](docker/README.md) to use Docker for a streamlined setup.

### Non-Containerized Installation

See [here](non-containerized/README.md) for manual installation instructions.

# CITATION

The author requests that any published work that utilizes these tools includes a citation to the following reference:

Rueda, M, Ariosa R. "Beacon v2 Reference Implementation: a toolkit to enable federated sharing of genomic and phenotypic data". _Bioinformatics_, btac568, https://doi.org/10.1093/bioinformatics/btac568

# AUTHOR

Written by Manuel Rueda, PhD. Info about CNAG Biomedical Informatics can be found at [https://www.cnag.eu](https://www.cnag.eu)

# COPYRIGHT and LICENSE

The software in this repository is copyrighted. See the LICENSE file included in this distribution.

