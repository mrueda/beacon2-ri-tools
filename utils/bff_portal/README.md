
# README `bff_portal`

The **BFF Portal** is a lightweight web-based platform that integrates a user-friendly frontend with a powerful API to enable live querying of MongoDB collections. This portal is designed for demonstration purposes, providing dynamic interaction with data while following the Beacon v2 Models specification.

## Features

- **Interactive UI:** A web-based interface for querying MongoDB collections with user-friendly forms and visualization.
- **Flexible API:** Direct access to MongoDB collections with simplified endpoints for dynamic data retrieval.
- **Cross-Collection Queries:** Perform advanced queries across multiple collections.
- **Pagination Support:** Easily navigate large datasets using `limit` and `skip` parameters.

## Notes

- Your BFF data has to be stored in MongoDB. Please refer to `bin/beacon` script documentation.
- The API does not strictly adhere to the full [Beacon v2 API](https://github.com/ga4gh-beacon/beacon-framework-v2) specification.
- Only `GET` requests are supported for querying data.
- Query flexibility allows direct access to MongoDB fields without request parameters or filtering terms.
- Responses return raw JSON documents similar to the Beacon v2 API's `_resultSets.results_`.
- Results from `genomicVariations` may be more concise for performance reasons.
- **Pagination:** Use `limit` and `skip` for paginated results. By default, 10 items are returned.
- If you want to perform similar operations on BFF but with ElasticSearch please refer to [Pheno-Search](https://github.com/mrueda/pheno-search).

## Installation

Install dependencies using `cpanm`:

```bash
cpanm Mojolicious MongoDB
```

## Running the Application

### 1. Start the Backend API

The backend API must be running before starting the frontend.

#### Development Mode

```bash
morbo backend/api.pl  # Runs on http://localhost:3000
```

#### Production Mode

```bash
hypnotoad backend/api.pl  # Runs on port 8080
```

### 2. Start the Frontend

The frontend runs on port 3001 by default. Start it after the backend.

#### Development Mode

```bash
perl frontend/app.pl daemon -l http://*:3001  # Runs on http://localhost:3001
```

#### Production Mode

```bash
hypnotoad frontend/app.pl  # Runs on port 8081
```

## API Examples

### Show Available Databases

```bash
curl http://localhost:3000/beacon/
```

### Show Collections Within a Database

```bash
curl http://localhost:3000/beacon/analyses
```

### Query a Collection by One or Two Fields

**Single Field Query:**

```bash
curl http://localhost:3000/beacon/individuals/id/HG02600
curl http://localhost:3000/beacon/genomicVariations/variantType/INDEL
curl http://localhost:3000/beacon/individuals/geographicOrigin_label/England
curl http://localhost:3000/beacon/genomicVariations/variantType/INDEL
curl http://localhost:3000/beacon/genomicVariations/caseLevelData_biosampleId/HG02600
curl http://localhost:3000/beacon/genomicVariations/molecularAttributes_geneIds/TP53
```

**Two Field Query:**

```bash
curl http://localhost:3000/beacon/genomicVariations/molecularAttributes_geneIds/ACE2/variantType/SNP
```

### Paginated Queries

```bash
curl "http://localhost:3000/beacon/individuals?limit=20&skip=40"
```

### Cross-Collection Queries

Retrieve related data across collections:

```bash
curl "http://localhost:3000/beacon/cross/individuals/HG00096/genomicVariations?limit=5&skip=10"
curl "http://localhost:3000/beacon/cross/individuals/HG00096/analyses"
```

## Using the Web Interface

1. Navigate to the portal in your browser: [http://localhost:3001](http://localhost:3001)
2. Choose between:
   - **Single Query:** Query a single MongoDB collection.
   - **Cross Query:** Perform cross-collection queries interactively.
3. View the formatted and syntax-highlighted JSON results.

## Credits

Adapted from [this app](https://gist.github.com/jshy/fa209c35d54551a70060) inspired by the Mojolicious Wiki.

