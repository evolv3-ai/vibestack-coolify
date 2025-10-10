#!/bin/bash

###############################################################################
# OCI Always Free Tier A1 Flex Capacity Checker
#
# Purpose: Check availability of VM.Standard.A1.Flex instances across all
#          availability domains before attempting Terraform deployments.
#
# Usage: ./check-oci-capacity.sh [OPTIONS]
#
# Options:
#   --region REGION          OCI region to check (default: home region)
#   --ocpus NUM             OCPUs to check for (default: 4)
#   --memory-gb NUM         Memory in GB (default: 24)
#   --json-output           Output JSON for Terraform (default: human-readable)
#
# Examples:
#   ./check-oci-capacity.sh                          # Check 4 OCPUs, 24GB in home region
#   ./check-oci-capacity.sh --ocpus 2 --memory-gb 12 # Check smaller config
#   ./check-oci-capacity.sh --region us-ashburn-1    # Check specific region
#   ./check-oci-capacity.sh --json-output            # JSON output for Terraform
#
# Requirements:
#   - OCI CLI configured with valid credentials or instance principal
#   - IAM permissions to list ADs and compute capacity
###############################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SHAPE="VM.Standard.A1.Flex"
OCPUS=4
MEMORY_GB=24
REGION=""
JSON_OUTPUT=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --region)
            REGION="$2"
            shift 2
            ;;
        --ocpus)
            OCPUS="$2"
            shift 2
            ;;
        --memory-gb)
            MEMORY_GB="$2"
            shift 2
            ;;
        --json-output)
            JSON_OUTPUT=true
            shift
            ;;
        -h|--help)
            grep '^#' "$0" | grep -v '#!/bin/bash' | sed 's/^# //g; s/^#//g'
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}" >&2
            echo "Usage: $0 [--region REGION] [--ocpus NUM] [--memory-gb NUM] [--json-output]" >&2
            exit 1
            ;;
    esac
done

# Set region flag
REGION_FLAG=""
if [ -n "$REGION" ]; then
    REGION_FLAG="--region $REGION"
else
    # Get home region
    REGION=$(oci iam region-subscription list --query 'data[?"is-home-region"]|[0]."region-name"' --raw-output 2>/dev/null || echo "")
    if [ -n "$REGION" ]; then
        REGION_FLAG="--region $REGION"
    fi
fi

if [ "$JSON_OUTPUT" = false ]; then
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════════════╗"
    echo "║         OCI Always Free Tier A1 Flex Capacity Check                      ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo -e "${BLUE}Region: ${REGION:-default}${NC}"
    echo -e "${BLUE}Configuration: ${OCPUS} OCPUs, ${MEMORY_GB}GB RAM${NC}"
    echo ""
fi

# Get tenancy OCID
TENANCY_OCID=$(oci iam availability-domain list --query 'data[0]."compartment-id"' --raw-output 2>/dev/null || echo "")

if [ -z "$TENANCY_OCID" ]; then
    if [ "$JSON_OUTPUT" = true ]; then
        echo '{"available": "false", "availability_domain": "", "error": "Unable to retrieve tenancy OCID"}'
    else
        echo -e "${RED}ERROR: Unable to retrieve tenancy OCID. Please check your OCI CLI configuration.${NC}" >&2
    fi
    exit 1
fi

# Get all availability domains
AVAILABILITY_DOMAINS=$(oci iam availability-domain list $REGION_FLAG --compartment-id "$TENANCY_OCID" 2>/dev/null | \
    python3 -c "import sys, json; print('\n'.join([d['name'] for d in json.load(sys.stdin)['data']]))" 2>/dev/null || echo "")

if [ -z "$AVAILABILITY_DOMAINS" ]; then
    if [ "$JSON_OUTPUT" = true ]; then
        echo '{"available": "false", "availability_domain": "", "error": "No availability domains found"}'
    else
        echo -e "${RED}ERROR: No availability domains found.${NC}" >&2
    fi
    exit 1
fi

if [ "$JSON_OUTPUT" = false ]; then
    AD_COUNT=$(echo "$AVAILABILITY_DOMAINS" | wc -l)
    echo -e "${GREEN}✓ Found $AD_COUNT availability domain(s) to check${NC}"
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════════"
    echo "  Checking Capacity: ${OCPUS} OCPUs, ${MEMORY_GB}GB RAM"
    echo "═══════════════════════════════════════════════════════════════════════════"
    echo ""
fi

# Function to check capacity for a single AD
check_capacity() {
    local ad="$1"

    if [ "$JSON_OUTPUT" = false ]; then
        echo -e "${BLUE}Checking: $ad${NC}"
        echo "  Shape: $SHAPE"
        echo "  Config: ${OCPUS} OCPUs, ${MEMORY_GB}GB RAM"
    fi

    # Create capacity report
    local result
    result=$(oci compute compute-capacity-report create \
        $REGION_FLAG \
        --compartment-id "$TENANCY_OCID" \
        --availability-domain "$ad" \
        --shape-availabilities "[{
            \"instanceShape\": \"$SHAPE\",
            \"instanceShapeConfig\": {
                \"ocpus\": $OCPUS,
                \"memoryInGBs\": $MEMORY_GB
            }
        }]" 2>&1) || true

    # Parse result for availability status
    if echo "$result" | grep -q '"availability-status": "AVAILABLE"'; then
        if [ "$JSON_OUTPUT" = false ]; then
            echo -e "  ${GREEN}✓ AVAILABLE${NC}"
        fi
        return 0
    elif echo "$result" | grep -q '"availability-status": "OUT_OF_HOST_CAPACITY"'; then
        if [ "$JSON_OUTPUT" = false ]; then
            echo -e "  ${RED}✗ OUT OF CAPACITY${NC}"
        fi
        return 1
    elif echo "$result" | grep -q '"availability-status": "CONSTRAINT_ERROR"'; then
        if [ "$JSON_OUTPUT" = false ]; then
            echo -e "  ${YELLOW}⚠ CONSTRAINT ERROR (invalid OCPU/memory config)${NC}"
        fi
        return 2
    else
        if [ "$JSON_OUTPUT" = false ]; then
            echo -e "  ${YELLOW}? UNKNOWN STATUS${NC}"
            echo "  Response: $result" | head -c 200
        fi
        return 3
    fi
}

# Track results
AVAILABLE_AD=""
CHECKED_COUNT=0

# Check each availability domain
while IFS= read -r ad; do
    CHECKED_COUNT=$((CHECKED_COUNT + 1))

    if check_capacity "$ad"; then
        AVAILABLE_AD="$ad"
        break
    fi

    if [ "$JSON_OUTPUT" = false ]; then
        echo ""
    fi
done <<< "$AVAILABILITY_DOMAINS"

# Output results
if [ "$JSON_OUTPUT" = true ]; then
    # JSON output for Terraform
    if [ -n "$AVAILABLE_AD" ]; then
        echo "{\"available\": \"true\", \"availability_domain\": \"$AVAILABLE_AD\"}"
        exit 0
    else
        echo "{\"available\": \"false\", \"availability_domain\": \"\"}"
        exit 1
    fi
else
    # Human-readable output
    echo "═══════════════════════════════════════════════════════════════════════════"
    echo "  SUMMARY"
    echo "═══════════════════════════════════════════════════════════════════════════"
    echo ""

    if [ -n "$AVAILABLE_AD" ]; then
        echo -e "${GREEN}✓ Capacity Available!${NC}"
        echo ""
        echo "  Availability Domain: $AVAILABLE_AD"
        echo ""
        echo "  You can deploy to this AD."
        echo "  Update your Terraform configuration with:"
        echo -e "    ${BLUE}availability_domain = \"$AVAILABLE_AD\"${NC}"
        echo ""
        exit 0
    else
        echo -e "${RED}✗ No capacity available in any availability domain.${NC}"
        echo ""
        echo "  Checked: $CHECKED_COUNT AD(s) in region $REGION"
        echo "  Configuration: $OCPUS OCPUs, ${MEMORY_GB}GB RAM"
        echo ""
        echo "  Options:"
        echo "    1. Try again later (capacity changes frequently)"
        echo "    2. Try a different region"
        echo "    3. Try a smaller configuration (2 OCPUs, 12GB RAM)"
        echo "    4. Use the monitoring script for automated retry:"
        echo "       ./scripts/monitor-and-deploy.sh --stack-id <STACK_OCID>"
        echo ""
        exit 1
    fi
fi
