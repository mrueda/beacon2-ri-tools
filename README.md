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
![version](https://img.shields.io/badge/version-2.0.6-blue)

---

**Documentation**: <a href="https://b2ri-documentation.readthedocs.io/" target="_blank">https://b2ri-documentation.readthedocs.io/</a>

**Docker Hub Image**: <a href="https://hub.docker.com/r/manuelrueda/beacon2-ri-tools/tags" target="_blank">https://hub.docker.com/r/manuelrueda/beacon2-ri-tools/tags</a>

---

**Actively maintained by the original author**

# Table of contents
- [Description](#description)
  - [B2RI Diagram](#b2ri-diagram)
  - [Roadmap](#roadmap)
- [Installation](#installation)
  - [Containerized](#containerized-installation-recommended)
  - [Non-Containerized](#non-containerized-installation)
- [Citation](#citation)
  - [Author](#author)
- [License](#copyright-and-license)

# DESCRIPTION

**beacon2-ri-tools** is part of the ELIXIR-Beacon v2 Reference Implementation (B2RI). It provides essential tools for ingesting, validating, and visualizing genomic and phenotypic data.

### Tools Included:
- **[Beacon Script](https://github.com/mrueda/beacon2-ri-tools/tree/main/bin/README.md)** (`bin/beacon`): A command-line tool for converting VCF data into BFF format. The tool also enables loading BFF (metadata + genomicVariations] into a MongoDB instance.
- **[Utility Suite](utils/README.md)**: A collection of tools to aid in data ingestion. Key among them:
  - **[BFF Validator](https://github.com/mrueda/beacon2-ri-tools/tree/main/utils/bff_validator)**: This tool includes an Excel template for converting your metadata (including phenotypic and clinical data) into Beacon v2 models, along with a validator for verifying and serializing the data into BFF format.
  - **[BFF Browser](https://github.com/mrueda/beacon2-ri-tools/tree/main/utils/bff_browser)**: Web App to display interactively BFF, in particular `genomicVariations` and `individuals`.
  - **[BFF Portal](https://github.com/mrueda/beacon2-ri-tools/tree/main/utils/bff_portal)**: A simple API + Web App to query BFF via MongoDB.

- **[CINECA Synthetic Cohort - EUROPE_UK1](https://github.com/mrueda/beacon2-ri-tools/tree/main/CINECA_synthetic_cohort_EUROPE_UK1)**: A synthetic dataset for testing and demonstration purposes.

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
                    _____v_____
                    |         |
                    |   BFF   |
                    | Browser | Visualization
                    |  (beta) |
                    |_________|

    ------------------------------------------------|||------------------------
    beacon2-ri-tools                                             beacon2-ri-api

## Roadmap 

**Latest Update: Nov-2024**

We know that this repository has been downloaded and used in many Beacon v2 implementations, so our plan is to keep supporting it and improving it. These are our plans:

- **Implement Beacon 2.1 changes**

    For `VCF`, this will imply adopting VRS nomenclature and maybe moving away from `LegacyVariation`. Adding support for Structural variants if present.

    For other entities, make sure that we follow the latest schema in `bff-validator`, and the Excel file.

    Update **CINECA** synthetic dataset.

- **Improve BFF Browser**

    So that it can handle multiple entities.

# INSTALLATION

You can install `beacon2-ri-tools` using one of two methods:

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

This repository is copyrighted, (C) 2021-2025 Manuel Rueda. See the LICENSE file included in this distribution.

