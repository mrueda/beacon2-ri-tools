# Quick Start `bff-tools`

This guide provides a one-page cheat sheet for common commands:

```bash
# Display help for the tool
bin/bff-tools --help
```

```bash
# Display man for the tool
bin/bff-tools --man
```

```bash
# Convert VCF to BFF
bin/bff-tools vcf -i test/test_1000G.vcf.gz -p test/param.yaml
```

```bash
# Validate metadata and convert to BFF
mkdir bff_out
bin/bff-tools validate -i Beacon-v2-Models_CINECA_UK1.xlsx --out-dir bff_out
```

# Usage

===  "Full Usage"

     --8<-- "../bin/README.md"

=== "Notes on `bff-tool validate`"

     {% include-markdown "../utils/bff_validator/README.md" start="<!--how-to-run-start-->" end="<!--how-to-run-end-->" %}
