# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

- Contact email now is @cnag.eu.
- `utils/bff-validator` 
  * Minor changes in STDOUT print.
- `test`
  * `genomicVariationsVcf.json.gz` file has `frequencyInPopulations` sorted by key.
- `bin/vcf2bff.pl`
  * Fixed typos. Added comments.

### Fixed

- `Dockerfile` from ubuntu to ubuntu:20.04 thanks to SJD folks 

## [2.0.0] - 2022-08-18

- Stable version released along with the accompanying paper:
  *  _Bioinformatics_, btac568, https://doi.org/10.1093/bioinformatics/btac568
- Works with [Beacon v2.0.0](https://github.com/ga4gh-beacon/beacon-v2/releases/tag/v2.0.0) specification.
