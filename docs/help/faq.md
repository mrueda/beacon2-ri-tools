# Frequently Asked Questions

??? faq "Are Beacon v2 `genomicVariations.variation.location.interval.{start,end}` coordinates 0-based or 1-based?"
    They are [0-based](http://docs.genomebeacons.org/formats-standards/#genome-coordinates).

    ##### last change 2025-03-23 by Manuel Rueda [:fontawesome-brands-github:](https://github.com/mrueda)

??? faq "I have an error when attempting to use `beacon vcf`, what should I do?"
    * In 9 out of 10 cases, the error comes from **BCFtools** and is related to the **reference genome** specified in the **parameters** [file](https://github.com/mrueda/beacon2-cbi-tools). The options are typically _hg19_, _hg38_ (which use `chr` prefixes), and _hs37_ (which do not). Ensure that your VCF’s contigs match the FASTA file or modify your `config.yaml` accordingly.
    
    * Additionally, **BCFtools** may complain about the number of fields (for example, in the INFO field). In such cases, you can try fixing the VCF manually or use:
    
    ```bash
    bcftools annotate -x INFO/IDREP input.vcf.gz | gzip > output.vcf.gz
    ```
    
    ##### last change 2025-03-23 by Manuel Rueda [:fontawesome-brands-github:](https://github.com/mrueda)

??? faq "Can I use SINGLE-SAMPLE and MULTI-SAMPLE VCFs?"
    Yes, you can use both. MongoDB allows for incremental loads so single-sample VCFs are acceptable (you don’t need to merge them into a multisample VCF). The connection between samples and variants is maintained in the `datasets` collection (or `cohorts`).
    
    ##### last change 2025-03-23 by Manuel Rueda [:fontawesome-brands-github:](https://github.com/mrueda)

??? faq "Can I use genomic VCF ([gVCF](https://gatk.broadinstitute.org/hc/en-us/articles/360035531812-GVCF-Genomic-Variant-Call-Format))?"
    Yes, but **first you will need to convert them** to a standard VCF. For example, you can use:
    
    ```bash
    bcftools convert --gvcf2vcf --fasta ref.fa input.g.vcf
    ```
    
    We are interested only in positions with ALT alleles. A “quick and dirty” solution with common Linux tools is:
    
    ```bash
    zcat input.g.vcf.gz | awk '$5 != "<NON_REF>"' | sed 's#,<NON_REF>##' | gzip > output.vcf.gz
    ```
    
    ##### last change 2025-03-23 by Manuel Rueda [:fontawesome-brands-github:](https://github.com/mrueda)

??? faq "In `bff-tools vcf` mode, why are we re-annotating VCFs | Can I use my own annotations?"

    The goal of re-annotation is to ensure consistency across the community. To create the `genomicVariationsVcf.json.gz` BFF, we parse an annotated VCF—this guarantees that the essential fields are present. Any previous annotations will be discarded. This approach has been instrumental in over 1,000 deployments for testing Beacon v2 API implementations.

    That said, if you know what you're doing and your `VCF` already contains the **essential** `ANN` fields, you can disable annotation by setting:

    ```yaml
    annotate: false
    ```
    
     in the parameters file. Do it at your own risk :smile:
    
    If you have internal annotations of value, you can add alternative genomic variations by completing the corresponding _tab_ in the provided [XLSX](https://github.com/mrueda/beacon2-cbi-tools/blob/main/utils/bff_validator/Beacon-v2-Models_template.xlsx). The resulting file (`genomicVariations.json`), together with `genomicVariationsVcf.json.gz`, will be loaded into the MongoDB collection _genomicVariations_. See [this tutorial](./tutorial-data-beaconization.md) for more details.
    
    ##### last change 2025-03-23 by Manuel Rueda [:fontawesome-brands-github:](https://github.com/mrueda)

??? faq "Is there an alternative to the Excel file for generating metadata/phenotypic data?"
    Yes. You can use CSV or JSON files directly as input for the `bff-validator` (a.k.a., `bff-tools validate`) utility. For detailed instructions, refer to the [bff-validator manual](https://github.com/mrueda/beacon2-cbi-tools/tree/main/utils/bff_validator).
    
    Alternatively, if your clinical data is in REDCap, OMOP CDM, Phenopackets v2, or raw CSV format, consider using the [Convert-Pheno](https://github.com/CNAG-Biomedical-Informatics/convert-pheno) tool.
    
    ##### last change 2025-03-23 by Manuel Rueda [:fontawesome-brands-github:](https://github.com/mrueda)

??? faq "`bff-validator` (a.k.a., `bff-tools validate)` specification mismatches"
    By default, `bff-validator` validates your data against the schemas bundled with your `beacon2-cbi-tools` version. If you encounter warnings (e.g., objects matching multiple possibilities in `oneOf` keywords), simply use the flag `--ignore-validation` when generating your `.json` files.
    
    ##### last change 2025-03-23 by Manuel Rueda [:fontawesome-brands-github:](https://github.com/mrueda)

??? faq "Do you load all variations present in a VCF file?"
    Yes, we do not apply filters (e.g., based on `FILTER` or `QUAL` fields) when loading variations, although we store those values in case they are needed later.
    
    ##### last change 2025-03-23 by Manuel Rueda [:fontawesome-brands-github:](https://github.com/mrueda)

??? faq "Do you have any recommendations on how to speed up the data ingestion process?"
    Metadata/phenoclinic data ingestion is typically fast (processing thousands to tens of thousands of values in seconds or minutes). However, **VCF processing** (especially for WGS data with >100M variants) can be slower. Consider the following:
    
    1. **Split your VCF by chromosome:**
       - Using community tools:
         ```bash
         bcftools view input.vcf.gz --regions chr1
         ```
       - Alternatively:
         ```bash
         tabix -p vcf input.vcf.gz
         tabix input.vcf.gz chr1 | bgzip > chr1.vcf.gz
         ```
       - Or with Linux tools:
         ```bash
         zcat input.vcf.gz | awk '/^#/ || $1=="chr1"' | bgzip > chr1.vcf.gz
         ```
    
    2. **Use [parallel processing](https://github.com/mrueda/beacon2-cbi-tools/tree/main/utils/bff_queue)** to submit jobs.
    
    ##### last change 2025-03-23 by Manuel Rueda [:fontawesome-brands-github:](https://github.com/mrueda)

??? faq "Can I use parallel jobs to perform data ingestion into MongoDB?"
    Yes, you can use parallel jobs; however, note that it may slightly slow down the ingestion process.
    
    ##### last change 2025-03-23 by Manuel Rueda [:fontawesome-brands-github:](https://github.com/mrueda)

??? faq "When performing incremental uploads, do I need to re-index MongoDB?"
    No. Indexes are created during the first data load and are updated automatically with each insert operation. Subsequent re-indexing attempts are discarded (the operation is **idempotent**).
    
    ##### last change 2025-03-23 by Manuel Rueda [:fontawesome-brands-github:](https://github.com/mrueda)

??? faq "Where do I get full WGS VCF for the CINECA synthetic cohort EUROPE UK1?"
    For full WGS data (≈20 GB for 2,504 synthetic individuals), request access and download from the [EGA](https://ega-archive.org/datasets/EGAD00001006673). See [this document](./synthetic-dataset.md) for details.
    
    ##### last change 2025-03-23 by Manuel Rueda [:fontawesome-brands-github:](https://github.com/mrueda)

??? faq "Are `beacon2-cbi-tools` free?"
    **Yes**, it is free and open source. The data ingestion tools are released under the [GNU General Public License v3.0](https://en.wikipedia.org/wiki/GNU_General_Public_License#Version_3), and the included [CINECA_synthetic_cohort_EUROPE_UK1](https://www.cineca-project.eu/cineca-synthetic-datasets) dataset is under a [CC-BY](https://en.wikipedia.org/wiki/Creative_Commons_licens) license.
    
    ##### last change 2025-03-23 by Manuel Rueda [:fontawesome-brands-github:](https://github.com/mrueda)

??? faq "Should I update to the `latest` version?"
    Yes. We recommend checking our GitHub repositories ([beacon2-cbi-tools](https://github.com/mrueda/beacon2-cbi-tools) and [beacon2-cbi-api](https://github.com/EGA-archive/beacon2-cbi-api)) for the latest updates.
    
    ##### last change 2025-03-23 by Manuel Rueda [:fontawesome-brands-github:](https://github.com/mrueda)

??? faq "How do I cite `beacon2-cbi-tools`?"

    You can cite the **Beacon v2 Reference Implementation** paper. Thx!

    !!! Note "Citation"
        Rueda, M, Ariosa R. "Beacon v2 Reference Implementation: a toolkit to enable federated sharing of genomic and phenotypic data". _Bioinformatics_, btac568, [DOI](https://doi.org/10.1093/bioinformatics/btac568).
    
    ##### last change 2025-03-23 by Manuel Rueda [:fontawesome-brands-github:](https://github.com/mrueda)
