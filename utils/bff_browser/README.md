# BFF Browser

## Overview  
The BFF Browser is an application that displays BFF files as interactive HTML. It works with the entities `genomicVariations` and `individuals`.

![BFF Dashboard](static/images/snapshot-dashboard-browser.png)

## Installation  
If you have already installed `beacon2-ri-tools`, the App should be installed automatically. If not, ensure you have Python 3 installed and then use the provided `requirements.txt` to install necessary dependencies:

```bash
pip install -r requirements.txt
```

## How to Run  
1. Navigate to the App folder:
    ```bash
    cd utils/browser
    ```
2. Run the application:
    ```bash
    python3 app.py
    ```

   Note that you can run it from any other directory too.

3. Open your web browser and go to:
    ```
    http://0.0.0.0:8000
    ```

The App includes precomputed examples for `genomicVariations` and `individuals` extracted from the **CINECA_synthetic_cohort_EUROPE_UK1** dataset.

---

## Browsing `genomicVariations`

The **BFF Browser Genomic Variations Browser** visualizes `genomicVariations` documents (stored as JSON arrays) using dynamic, HTML-embedded tables.

![BFF Genomic Variations Browser](static/images/snapshot-BFF-genomic-variations-browser.png)

This tool is designed to facilitate the analysis of variations with a **HIGH** impact annotation, offering a convenient and targeted exploration method.

### Preparing the Files  
To generate the necessary files, update your parameters file when **processing your VCF** using the following command:

Example:

```bash
beacon vcf -i my.vcf -p param.yaml
```

Ensure your `param.yaml` includes:

```yaml
bff2html: true
```

By default, the browser processes all `.lst` files in the `paneldir` folder. The `paneldir` folder is set at the `beacon` **configuration file**. You can include your own panels if needed. Once processing is complete, a static HTML page will be available in the `<job_id>/browser` directory. This page serves as the input for the **BFF Browser**.

### Features  

1. **Gene Panel Support**  
   - Variations are displayed in **HTML tabs** organized by gene panels.
   - **Gene Panels**: Simple text files with a `.lst` extension containing a list of gene names.
   - **Default Directory**: `$beacon_path/browser/data`.
   - **Customization**: Modify the directory using the `paneldir` parameter in the `config.yaml` file.
   - **Extendability**: You can create and add additional gene panels.

2. **Dynamic Tables**  
   - The browser generates searchable and sortable tables directly in HTML.
   - **Key Features**:
     - Column reordering.
     - Advanced search with regular expressions (e.g., `rs12(3|4) (tp53|ace2) splice`).

3. **Filtered Display**
   - Only variations with a **HIGH** impact annotation are included.
   - Variations are filtered and displayed according to the `.lst` files in the `paneldir` folder.

---

## Browsing `individuals`

When browsing `individuals`, the input file should be a JSON file (e.g., `individuals.json`). The browser will handle this file to display the relevant data interactively.

![BFF Individuals Browser](static/images/snapshot-BFF-individuals-browser.png)


## New Feature: Combined Genomic Variations & Individuals Search

- Merge genomic variant data with individual biosample data.
- **Client-based** interactive, searchable, and paginated table view.
- Toggle visibility of the variations column.

## How to Use

1. **Combined View by Path**  
   - Enter paths for genomic and individuals JSON files.  
   - View combined results.

2. **Combined Example**  
   - See a demo with sample data.

## Key Features

- Cross-linked data by Biosample ID.  
- Toggleable variations column.  
- Pagination and search for large datasets.

![BFF Combined Browser](static/images/snapshot-BFF-combined-browser.png)

