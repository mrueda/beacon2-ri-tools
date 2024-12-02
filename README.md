[![Docker build](https://github.com/mrueda/beacon2-ri-tools/actions/workflows/docker-build.yml/badge.svg)](https://github.com/mrueda/beacon2-ri-tools/actions/workflows/docker-build.yml)
[![Documentation Status](https://readthedocs.org/projects/b2ri-documentation/badge/?version=latest)](https://b2ri-documentation.readthedocs.io/en/latest/?badge=latest)
![Maintenance status](https://img.shields.io/badge/maintenance-actively--developed-brightgreen.svg)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Docker Pulls](https://badgen.net/docker/pulls/manuelrueda/beacon2-ri-tools?icon=docker&label=pulls)](https://hub.docker.com/r/manuelrueda/beacon2-ri-tools/)
[![Docker Pulls EGA-archive](https://badgen.net/docker/pulls/beacon2ri/beacon_reference_implementation?icon=docker&label=EGA-archive-pulls)](https://hub.docker.com/r/beacon2ri/beacon_reference_implementation/)
![version](https://img.shields.io/badge/version-2.0.4-blue)

**Documentation**: <a href="https://b2ri-documentation.readthedocs.io/" target="_blank">https://b2ri-documentation.readthedocs.io/</a>

**CLI Source Code**: <a href="https://github.com/mrueda/beacon2-ri-tools" target="_blank">https://github.com/mrueda/beacon2-ri-tools</a>

**Docker Hub Image**: <a href="https://hub.docker.com/r/manuelrueda/beacon2-ri-tools/tags" target="_blank">https://hub.docker.com/r/manuelrueda/beacon2-ri-tools/tags</a>

**Actively maintained by the original author**

# Description

**beacon2-ri-tools** repository, part of the ELIXIR-Beacon v2 Reference Implementation (B2RI), includes:

- The [beacon](https://github.com/mrueda/beacon2-ri-tools/tree/main/bin/README.md) script
- A suite of [utilities](https://github.com/mrueda/beacon2-ri-tools/tree/main/utils) aiding in data ingestion
- The [CINECA\_synthetic\_cohort\_EUROPE\_UK1](https://github.com/mrueda/beacon2-ri-tools/tree/main/CINECA_synthetic_cohort_EUROPE_UK1) dataset

## Roadmap 

**Latest Update: Nov-2024**

We know that this repository has been downloaded and used in many Beacon v2 implementations, so our plan is to keep supporting it and improving it. These are our plans:

- **Implement Beacon 2.1 changes**

    For `VCF`, this will imply adopting VRS nomenclature and maybe moving away from `LegacyVariation`. Adding support for Structural variants if present.

    For other entities, make sure that we follow the latest schema in `bff-validator`, and the Excel file.

    Update **CINECA** synthetic dataset.

- **Improve Genomic Variations Browser**

    So that it works as a web-server instead of a static web-page.

