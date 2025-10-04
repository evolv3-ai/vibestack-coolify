#!/bin/bash

# Coolify OCI Deployment Troubleshooting Script
# This script helps diagnose and resolve common deployment issues

set -e

echo "🔍 Coolify OCI Deployment Troubleshooter"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if terraform is installed
check_terraform() {
    print_status "Checking Terraform installation..."
    if command -v terraform &> /dev/null; then
        TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
        print_success "Terraform $TERRAFORM_VERSION is installed"
    else
        print_error "Terraform is not installed or not in PATH"
        exit 1
    fi
}

# Check OCI CLI configuration
check_oci_config() {
    print_status "Checking OCI CLI configuration..."
    if command -v oci &> /dev/null; then
        if oci iam region list &> /dev/null; then
            print_success "OCI CLI is configured and working"
        else
            print_warning "OCI CLI is installed but may not be properly configured"
        fi
    else
        print_warning "OCI CLI is not installed (optional but recommended)"
    fi
}

# Check terraform.tfvars file
check_tfvars() {
    print_status "Checking terraform.tfvars configuration..."
    if [ -f "terraform.tfvars" ]; then
        print_success "terraform.tfvars file found"
        
        # Check required variables
        required_vars=("tenancy_ocid" "region" "ssh_authorized_keys" "coolify_root_user_email")
        for var in "${required_vars[@]}"; do
            if grep -q "^${var}" terraform.tfvars; then
                print_success "✓ $var is configured"
            else
                print_error "✗ $var is missing from terraform.tfvars"
            fi
        done
    else
        print_error "terraform.tfvars file not found"
        print_status "Creating terraform.tfvars from example..."
        cp terraform.tfvars.example terraform.tfvars
        print_warning "Please edit terraform.tfvars with your configuration"
    fi
}

# Check for common deployment issues
check_deployment_state() {
    print_status "Checking Terraform state..."
    
    if [ -f ".terraform.lock.hcl" ]; then
        print_success "Terraform is initialized"
    else
        print_warning "Terraform not initialized. Run 'terraform init'"
        return
    fi
    
    # Check for failed resources
    if terraform show -json 2>/dev/null | jq -e '.values.root_module.resources[] | select(.values.state == "FAILED")' &> /dev/null; then
        print_error "Found failed resources in state"
        print_status "Failed resources:"
        terraform show -json | jq -r '.values.root_module.resources[] | select(.values.state == "FAILED") | .address'
    fi
}

# Suggest recovery actions for 500 errors
suggest_recovery() {
    print_status "Recovery suggestions for 500 Internal Server Error:"
    echo ""
    echo "1. 🔄 Retry the deployment (OCI service issues are often temporary):"
    echo "   terraform apply -auto-approve"
    echo ""
    echo "2. 🏗️ Try a different availability domain:"
    echo "   Add to terraform.tfvars: availability_domain = \"<different-ad>\""
    echo ""
    echo "3. 📦 Update to latest provider version:"
    echo "   terraform init -upgrade"
    echo ""
    echo "4. 🧹 Clean and retry:"
    echo "   terraform destroy -auto-approve"
    echo "   terraform apply -auto-approve"
    echo ""
    echo "5. 🔍 Check OCI service status:"
    echo "   Visit: https://ocistatus.oraclecloud.com/"
    echo ""
}

# List available availability domains
list_availability_domains() {
    print_status "Available Availability Domains:"
    if command -v oci &> /dev/null && [ -f "terraform.tfvars" ]; then
        TENANCY_OCID=$(grep "tenancy_ocid" terraform.tfvars | cut -d'"' -f2)
        if [ ! -z "$TENANCY_OCID" ]; then
            oci iam availability-domain list --compartment-id "$TENANCY_OCID" --query 'data[].name' --raw-output 2>/dev/null || print_warning "Could not fetch ADs via OCI CLI"
        fi
    else
        print_warning "OCI CLI not available or terraform.tfvars missing"
    fi
}

# Check OCI service limits
check_service_limits() {
    print_status "Checking OCI service limits..."
    if command -v oci &> /dev/null && [ -f "terraform.tfvars" ]; then
        TENANCY_OCID=$(grep "tenancy_ocid" terraform.tfvars | cut -d'"' -f2)
        if [ ! -z "$TENANCY_OCID" ]; then
            print_status "VM.Standard.A1.Flex limits:"
            oci limits resource-availability get --compartment-id "$TENANCY_OCID" --service-name compute --limit-name vm-standard-a1-flex-core-count 2>/dev/null || print_warning "Could not check service limits"
        fi
    fi
}

# Main execution
main() {
    echo ""
    check_terraform
    echo ""
    check_oci_config
    echo ""
    check_tfvars
    echo ""
    check_deployment_state
    echo ""
    list_availability_domains
    echo ""
    check_service_limits
    echo ""
    suggest_recovery
    echo ""
    print_success "Troubleshooting complete!"
}

# Run main function
main