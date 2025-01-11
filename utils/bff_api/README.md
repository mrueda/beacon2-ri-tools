
# README bff-api

Here we provide a lightweight API to enable basic queries to MongoDB. This API was created for demonstration purposes only.  

### Notes

- This API is not built by loading any OpenAPI-based Beacon v2 specification.
- This API does not incorporate all the endpoints available in the [Beacon v2 API](https://github.com/ga4gh-beacon/beacon-framework-v2).
- This API only accepts requests using the `GET` HTTP method.
- This API only allows queries to the _collections_ present in the _beacon_ database. In Beacon v2 API nomenclature, these will be the resources present in the endpoint **entry_types**.
- Since we are querying MongoDB directly, our queries are more flexible/transparent than those you'll make to the Beacon v2 API.
  - We are not using _request parameters_.
  - We are not using _filtering terms_.
  - Instead, we use the same nomenclature present in [Beacon v2 Models](https://beacon-schema-2.readthedocs.io/en/latest).
  - We don't restrict cross-collection queries to [those](https://github.com/EGA-archive/beacon-2.x/wiki/Implementation#entities) in the Beacon v2 API.
- The responses only include the JSON documents (i.e., the element _resultSets.results_ in Beacon v2 API).
- Usually the result returns documents (full objects), but queries involving the `genomicVariations` collection may provide less "verbose" results.
- **Pagination**: Endpoints returning lists of documents support pagination through the query parameters `limit` and `skip`. By default, the API returns 10 items if these parameters are not specified.

## Installation

```bash
cpanm Mojolicious MongoDB
```

## How to Run

```bash
morbo bff-api  # development (default: port 3000)
```
or 

```bash
hypnotoad bff-api  # production (port 8080)
```

## Examples

Please separate nested terms/properties with an underscore (`_`). We allow searching up to **two terms**.

### Info Queries

Show databases:
```bash
curl http://localhost:3000/beacon/
```

Show collections within a database:
```bash
curl http://localhost:3000/beacon/analyses
```

### Queries on One Collection at a Time

Queries support up to two terms. Results will display the first match.

**One term:**
```bash
curl http://localhost:3000/beacon/individuals/HG02600
curl http://localhost:3000/beacon/individuals/geographicOrigin_label/England
curl http://localhost:3000/beacon/genomicVariations/variantType/INDEL
curl http://localhost:3000/beacon/genomicVariations/caseLevelData_biosampleId/HG02600
curl http://localhost:3000/beacon/genomicVariations/molecularAttributes_geneIds/TP53
```

**Two terms:**
```bash
curl http://localhost:3000/beacon/genomicVariations/molecularAttributes_geneIds/ACE2/variantType/SNP
```

### Queries with Pagination

Endpoints that return multiple results support pagination using `limit` and `skip` query parameters. For example:
```bash
curl "http://localhost:3000/beacon/individuals?limit=20&skip=40"
```
This fetches 20 records from the `individuals` collection, skipping the first 40 records.

For cross queries:
```bash
curl "http://localhost:3000/beacon/cross/individuals/HG00096/genomicVariations?limit=5&skip=10"
```
This returns 5 `variantInternalId` values, skipping the first 10 matches.

### Queries by ID, Two Collections at a Time

```bash
curl http://localhost:3000/beacon/cross/individuals/HG00096/analyses
curl http://localhost:3000/beacon/cross/individuals/HG00096/genomicVariations  # variantInternalId for first 10 matches
```

### Credits

Adapted from [this app](https://gist.github.com/jshy/fa209c35d54551a70060) extracted from the Mojolicious Wiki.
