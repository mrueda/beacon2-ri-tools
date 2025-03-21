#!/usr/bin/env bash
set -euo pipefail

echo "Info: Testing <beacon2-cbi-tools> ..."

# Change to the ../test directory relative to the script's location
cd "$(dirname "$0")/../test"

# Define paths and reference output
BFF_TOOLS="../bin/bff-tools"
REFERENCE_RESULT="beacon_166403275914916"

echo "Info: Cwd => $(pwd) ..."

# Check that required tools are installed
for cmd in jq zcat; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: '$cmd' is not installed."
    exit 1
  fi
done

# Ensure the beacon binary exists and is executable
if [[ ! -x "$BFF_TOOLS" ]]; then
  echo "Error: $BFF_TOOLS executable not found or not executable"
  exit 1
fi

# Ensure the test files exist
if [[ ! -f test_1000G.vcf.gz || ! -f param.yaml ]]; then
  echo "Error: Required test files (test_1000G.vcf.gz or param.yaml) are missing"
  exit 1
fi

# Run the test command and capture logs
"$BFF_TOOLS" vcf -i test_1000G.vcf.gz -p param.yaml > log.txt 2>&1

# Identify the latest result directory
TEST_RESULT=$(ls -td -- */ | head -n 1)

if [[ -z "$TEST_RESULT" ]]; then
  echo "Error: No test result directory created"
  exit 1
fi

echo "Info: Using test results from directory: $TEST_RESULT"

# Compare the outputs using diff's exit status
if diff <(zcat "$TEST_RESULT/vcf/genomicVariationsVcf.json.gz" | jq 'del(.[]._info)' -S) \
        <(zcat "$REFERENCE_RESULT/vcf/genomicVariationsVcf.json.gz" | jq 'del(.[]._info)' -S); then
  echo "Info: Congratulations, <beacon2-cbi-tools> are deployed!"
else
  echo "Error: Deployment test failed. Differences detected in test output"
  exit 1
fi

