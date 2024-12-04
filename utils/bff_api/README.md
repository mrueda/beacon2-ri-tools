# README bff-api

Here we provide a light API to enable basic queries to MongoDB. This API was created for demonstration purposes only.  

### Notes:

* This API is not built by loading any OpenAPI-based Beacon v2 specification.
* This API does not incorporate all the endpoints available in [Beacon v2 API](https://github.com/ga4gh-beacon/beacon-framework-v2).
* This API only accepts requests using `GET` http method.
* This API only allows to make queries to the _collections_ present in _beacon_ database. In Beacon v2 API nomenclature, these will be the resources present in the endpoint **entry_types**.
* Since we're querying MongoDB directly, our queries are more flexible/transparent than those you'll make to the Beacon v2 API.
    * We are not using _request paramaters_.
    * We are not using _filtering terms_.
    * Instead, we use the same nomenclature present in [Beacon v2 Models](https://beacon-schema-2.readthedocs.io/en/latest).
    * We don't restrict cross-collection queries to [those](https://github.com/EGA-archive/beacon-2.x/wiki/Implementation#entities) in Beacon v2 API.
    * The responses only include the JSON documents (i.e., the element _resultSets.results_ in Beacon v2 API)
    * Usually the result return documents (full objects) but queries including `genomicVariations` collection may provide less "verbose" results.
    
## Installation

    $ cpanm Mojolicious MongoDB

## How to run

    $ morbo bff-api # development (default: port 3000)
or 

    $ hypnotoad bff-api # production (port 8080)


## Examples

Please separate nested terms/properties with an underscore (`_`). We allow searcing up to **two terms**.

Info queries
```
# Show database

curl http://localhost:3000/beacon/

# Show collection

curl http://localhost:3000/beacon/analyses
```

Queries on 1 collection at a time (we allow up searcing up to two terms). Results will display 1st match.

```
# One term:

curl http://localhost:3000/beacon/individuals/HG02600
curl http://localhost:3000/beacon/individuals/geographicOrigin_label/England
curl http://localhost:3000/beacon/genomicVariations/variantType/INDEL
curl http://localhost:3000/beacon/genomicVariations/caseLevelData_biosampleId/HG02600
curl http://localhost:3000/beacon/genomicVariations/molecularAttributes_geneIds/TP53

# Two terms:

curl http://localhost:3000/beacon/genomicVariations/molecularAttributes_geneIds/ACE2/variantType/SNP
```

Queries by Id, 2 collections at a time:
```
curl http://localhost:3000/beacon/cross/individuals/HG00096/analyses
curl http://localhost:3000/beacon/cross/individuals/HG00096/genomicVariations # varianInternalId for first 10 matches
```

### Credits

Adapted from [this app](https://gist.github.com/jshy/fa209c35d54551a70060) extracted from Mojolicius Wiki.
