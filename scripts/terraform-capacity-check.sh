#!/bin/bash

###############################################################################
# Terraform External Data Source Wrapper for OCI Capacity Checking
#
# Purpose: Wrapper script for Terraform external data source to check
#          OCI A1 Flex capacity before deployment.
#
# Input: JSON from Terraform via stdin
#   {
#     "region": "us-ashburn-1",
#     "ocpus": "4",
#     "memory_gb": "24",
#     "tenancy_id": "ocid1.tenancy.oc1.."
#   }
#
# Output: JSON to stdout
#   {"available": "true", "availability_domain": "AD-1"}
#   or
#   {"available": "false", "availability_domain": ""}
#
# Note: This script runs inside OCI Resource Manager with instance principal
#       authentication, so no --profile flag is needed.
###############################################################################

set -euo pipefail

# Read JSON input from Terraform
INPUT=$(cat)

# Parse input JSON
REGION=$(echo "$INPUT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('region', ''))")
OCPUS=$(echo "$INPUT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('ocpus', '4'))")
MEMORY_GB=$(echo "$INPUT" | python3 -c "import sys, json; print(json.load(sys.stdin).get('memory_gb', '24'))")

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Call the main capacity check script with JSON output
"$SCRIPT_DIR/check-oci-capacity.sh" \
    --region "$REGION" \
    --ocpus "$OCPUS" \
    --memory-gb "$MEMORY_GB" \
    --json-output
