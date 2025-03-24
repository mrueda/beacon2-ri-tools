
<div align="center">
    <a href="https://github.com/CNAG-Biomedical-Informatics/beacon2-cbi-tools">
        <img src="https://raw.githubusercontent.com/CNAG-Biomedical-Informatics/beacon2-cbi-tools/main/docs/img/logo.png" width="200" alt="beacon2-cbi-tools">
    </a>
</div>

<div align="center" style="font-family: Consolas, monospace;">
    <h1>beacon2-cbi-tools</h1>
</div>

[![Docker build](https://github.com/CNAG-Biomedical-Informatics/beacon2-cbi-tools/actions/workflows/docker-build.yml/badge.svg)](https://github.com/CNAG-Biomedical-Informatics/beacon2-cbi-tools/actions/workflows/docker-build.yml)
[![Documentation Status](https://github.com/cnag-biomedical-informatics/beacon2-cbi-tools/actions/workflows/documentation.yml/badge.svg)](https://github.com/cnag-biomedical-informatics/beacon2-cbi-tools/actions/workflows/documentation.yml)
![Maintenance status](https://img.shields.io/badge/maintenance-actively--developed-brightgreen.svg)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Docker Pulls](https://badgen.net/docker/pulls/manuelrueda/beacon2-cbi-tools?icon=docker&label=beacon2-cbi-tools-pulls)](https://hub.docker.com/r/manuelrueda/beacon2-cbi-tools/)
[![Docker Pulls](https://badgen.net/docker/pulls/manuelrueda/beacon2-ri-tools?icon=docker&label=legacy-beacon2-ri-tools-pulls)](https://hub.docker.com/r/manuelrueda/beacon2-ri-tools/)
[![Docker Pulls EGA-archive](https://badgen.net/docker/pulls/beacon2ri/beacon_reference_implementation?icon=docker&label=legacy-EGA-archive-pulls)](https://hub.docker.com/r/beacon2ri/beacon_reference_implementation/)
![version](https://img.shields.io/badge/version-2.0.8-blue)

---


✨ **New documentation:** <a href="https://cnag-biomedical-informatics.github.io/beacon2-cbi-tools" target="_blank">https://cnag-biomedical-informatics.github.io/beacon2-cbi-tools</a>

🐳 **Docker Hub Image:** <a href="https://hub.docker.com/r/manuelrueda/beacon2-cbi-tools/tags" target="_blank">https://hub.docker.com/r/manuelrueda/beacon2-cbi-tools/tags</a>

🚫 **Legacy B2RI Documentation:** <a href="https://b2ri-documentation.readthedocs.io/" target="_blank">https://b2ri-documentation.readthedocs.io/</a>

---

**Actively maintained by CNAG Biomedical Informatics**

> **Note:** This repository was formerly known as **beacon2-ri-tools** (Beacon v2 Reference Implementation). It has been renamed to **beacon2-cbi-tools (CNAG Biomedical Informatics)** to better reflect its identity under CNAG.

# Table of contents
- [Description](#description)
  - [Overview](#overview)
  - [Tools included](#tools-included)
  - [System Diagram](#system-diagram)
  - [Roadmap](#roadmap)
- [Installation](#installation)
  - [Containerized](#containerized-installation-recommended)
  - [Non-Containerized](#non-containerized-installation)
- [Citation](#citation)
  - [Author](#author)
- [License](#copyright-and-license)

# DESCRIPTION

<!--description-start-->

## Overview

**beacon2-cbi-tools** is a suite of tools originally developed as part of the ELIXIR–Beacon v2 Reference Implementation, now continuing under [CNAG](https://www.cnag.eu) Biomedical Informatics. It provides essential functionality around the Beacon Friendly Format (BFF) data exchange format, including:

- **Validating XLSX/JSON** files against Beacon v2 schemas
- **Converting VCF** files into BFF (genomicVariations)
- **Loading BFF** data (metadata and genomic variations) **into MongoDB**

This toolkit streamlines data preparation, validation, and ingestion for federated genomic and phenotypic data sharing under Beacon v2. The resulting BFF-formatted data **can be used with any implementation of the [Beacon v2 API specification](https://docs.genomebeacons.org/) that operates on MongoDB**.

## Tools Included

### [BFF-Tools script](https://github.com/CNAG-Biomedical-Informatics/beacon2-cbi-tools/tree/main/bin/README.md) (`bin/bff-tools`):  
  A command-line tool for converting VCF data into BFF format and inserting the resulting BFF data into a MongoDB instance.

The tool offers four modes:

  1. **vcf**: Convert a VCF.gz file into BFF format.

  2. **load**: Load BFF-formatted data into a MongoDB instance.

  3. **full**: Perform both VCF conversion and MongoDB loading.

  4. **validate**: Validate XLSX or JSON metadata against Beacon v2 schemas and serialize into BFF. An [Excel template](https://github.com/CNAG-Biomedical-Informatics/beacon2-cbi-tools/blob/main/CINECA_synthetic_cohort_EUROPE_UK1/Beacon-v2-Models_CINECA_UK1.xlsx) is provided to help structure your metadata.

### [Utility Suite](https://github.com/CNAG-Biomedical-Informatics/beacon2-cbi-tools/tree/main/utils):  

A collection of support tools to aid in data ingestion. Key among them:

  - **[BFF-Browser](https://github.com/CNAG-Biomedical-Informatics/beacon2-cbi-tools/tree/main/utils/bff_browser)**:  

    A web application for interactive visualization of BFF data, particularly `genomicVariations` and `individuals`.

  - **[BFF-Portal](https://github.com/CNAG-Biomedical-Informatics/beacon2-cbi-tools/tree/main/utils/bff_portal)**:  

    A simple API and web application to query BFF data via MongoDB.

### [CINECA Synthetic Cohort - EUROPE_UK1](https://github.com/CNAG-Biomedical-Informatics/beacon2-cbi-tools/tree/main/CINECA_synthetic_cohort_EUROPE_UK1):  

A synthetic dataset for testing and demonstration purposes.

## System Diagram

                * Beacon v2 - CBI Tools *

                    ___________
              XLSX  |          |
               or   | Metadata | (incl. Phenotypic data)
              JSON  |__________|
                         |
                         |
                         | bff-tools validate
                         |                                   Beacon v2
    _________        ____v____            __________          ______
    |       |        |       |            |          |        |     | <---- Request
    |  VCF  | -----> |  BFF  | ---------> | Database | <----> | API |
    |_______|        |_ _____|            |__________|        |_____| ----> Response
                         |                  MongoDB
           bff-tools vcf |  bff-tools load
                         |
                         |
                      Optional (utils)
                         |
                    _____v_____
                    |         |
                    | utils/  |
                    |  bff-   |
                    | browser | Visualization
                    | (beta)  |
                    |_________|

    -----------------------------------------------|||---------------------------
    beacon2-cbi-tools                                     e.g. beacon2-ri-api
                                                               beacon2-pi-api
                                                               java-beacon-v2.api   
                                                               ...
<!--description-end-->

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

