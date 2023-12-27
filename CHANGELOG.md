# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.1] - 2022-12-27

### Added

### Changed

- Updated contact email to @cnag.eu
- `utils/bff-validator`
  * Adjusted STDOUT printout details
- `test`
  * Sorted `frequencyInPopulations` by key in `genomicVariationsVcf.json.gz`
- `bin/vcf2bff.pl`
  * Corrected typos and enhanced code comments.
- Docker Hub location updated to `manuelrueda/beacon2-ri-tools`
- Updated `README.md`

### Fixed

- `Dockerfile` 
  * from `ubuntu` to `ubuntu:20.04` thanks to SJD folks 

## [2.0.0] - 2022-08-18

- Stable version released along with the accompanying paper:
  *  _Bioinformatics_, btac568, https://doi.org/10.1093/bioinformatics/btac568
- Works with [Beacon v2.0.0](https://github.com/ga4gh-beacon/beacon-v2/releases/tag/v2.0.0) specification.
