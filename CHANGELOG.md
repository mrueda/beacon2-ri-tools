# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.3] - 2024-05-24

### Changed

- Added Unicode support to bff-validator

## [2.0.2] - 2024-02-07

### Changed

- Updated `docker-compose.yml`
- Changed `config.yml` to enable connecting to @mongo from within `beacon2-ri-tools` container

## [2.0.1] - 2024-01-22

### Changed

- Updated contact email to @cnag.eu
- `utils/bff-validator`
  * Adjusted STDOUT printout details
- `test`
  * Sorted `frequencyInPopulations` by key in `genomicVariationsVcf.json.gz`
- Docker Hub location updated to `manuelrueda/beacon2-ri-tools`
- Moved `BEACON` to `lib/BEACON`
- Updated READMEs

### Fixed

- `Dockerfile` 
  * from `ubuntu` to `ubuntu:20.04` thanks to SJD folks 

## [2.0.0] - 2022-08-18

- Stable version released along with the accompanying paper:
  *  _Bioinformatics_, btac568, https://doi.org/10.1093/bioinformatics/btac568
- Works with [Beacon v2.0.0](https://github.com/ga4gh-beacon/beacon-v2/releases/tag/v2.0.0) specification.
