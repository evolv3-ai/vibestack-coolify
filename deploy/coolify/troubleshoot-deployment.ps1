# Coolify OCI Deployment Troubleshooting Script (PowerShell)
# This script helps diagnose and resolve common deployment issues

param(
    [switch]$Detailed
)

Write-Host "🔍 Coolify OCI Deployment Troubleshooter" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

function Write-Status {
    param($Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param($Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param($Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param($Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check if terraform is installed
function Test-Terraform {
    Write-Status "Checking Terraform installation..."
    try {
        $terraformVersion = terraform version -json | ConvertFrom-Json
        Write-Success "Terraform $($terraformVersion.terraform_version) is installed"
        return $true
    }
    catch {
        Write-Error "Terraform is not installed or not in PATH"
        return $false
    }
}

# Check OCI CLI configuration
function Test-OciConfig {
    Write-Status "Checking OCI CLI configuration..."
    try {
        $null = Get-Command oci -ErrorAction Stop
        $null = oci iam region list 2>$null
        Write-Success "OCI CLI is configured and working"
    }
    catch {
        Write-Warning "OCI CLI is not installed or not properly configured"
    }
}

# Check terraform.tfvars file
function Test-TfVars {
    Write-Status "Checking terraform.tfvars configuration..."
    
    if (Test-Path "terraform.tfvars") {
        Write-Success "terraform.tfvars file found"
        
        $requiredVars = @("tenancy_ocid", "region", "ssh_authorized_keys", "coolify_root_user_email")
        $content = Get-Content "terraform.tfvars"
        
        foreach ($var in $requiredVars) {
            if ($content -match "^$var") {
                Write-Success "✓ $var is configured"
            }
            else {
                Write-Error "✗ $var is missing from terraform.tfvars"
            }
        }
    }
    else {
        Write-Error "terraform.tfvars file not found"
        if (Test-Path "terraform.tfvars.example") {
            Write-Status "Creating terraform.tfvars from example..."
            Copy-Item "terraform.tfvars.example" "terraform.tfvars"
            Write-Warning "Please edit terraform.tfvars with your configuration"
        }
    }
}

# Check deployment state
function Test-DeploymentState {
    Write-Status "Checking Terraform state..."
    
    if (Test-Path ".terraform.lock.hcl") {
        Write-Success "Terraform is initialized"
    }
    else {
        Write-Warning "Terraform not initialized. Run 'terraform init'"
        return
    }
    
    # Check for failed resources
    try {
        $state = terraform show -json | ConvertFrom-Json
        $failedResources = $state.values.root_module.resources | Where-Object { $_.values.state -eq "FAILED" }
        
        if ($failedResources) {
            Write-Error "Found failed resources in state"
            Write-Status "Failed resources:"
            $failedResources | ForEach-Object { Write-Host "  - $($_.address)" }
        }
    }
    catch {
        Write-Warning "Could not parse Terraform state"
    }
}

# Suggest recovery actions
function Show-RecoveryActions {
    Write-Status "Recovery suggestions for 500 Internal Server Error:"
    Write-Host ""
    Write-Host "1. 🔄 Retry the deployment (OCI service issues are often temporary):" -ForegroundColor White
    Write-Host "   terraform apply -auto-approve" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. 🏗️ Try a different availability domain:" -ForegroundColor White
    Write-Host "   Add to terraform.tfvars: availability_domain = `"<different-ad>`"" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. 📦 Update to latest provider version:" -ForegroundColor White
    Write-Host "   terraform init -upgrade" -ForegroundColor Gray
    Write-Host ""
    Write-Host "4. 🧹 Clean and retry:" -ForegroundColor White
    Write-Host "   terraform destroy -auto-approve" -ForegroundColor Gray
    Write-Host "   terraform apply -auto-approve" -ForegroundColor Gray
    Write-Host ""
    Write-Host "5. 🔍 Check OCI service status:" -ForegroundColor White
    Write-Host "   Visit: https://ocistatus.oraclecloud.com/" -ForegroundColor Gray
    Write-Host ""
}

# List available availability domains
function Show-AvailabilityDomains {
    Write-Status "Available Availability Domains:"
    
    if ((Get-Command oci -ErrorAction SilentlyContinue) -and (Test-Path "terraform.tfvars")) {
        try {
            $tfvarsContent = Get-Content "terraform.tfvars"
            $tenancyLine = $tfvarsContent | Where-Object { $_ -match '^tenancy_ocid\s*=' }
            
            if ($tenancyLine) {
                $tenancyOcid = ($tenancyLine -split '"')[1]
                $ads = oci iam availability-domain list --compartment-id $tenancyOcid --query 'data[].name' --raw-output 2>$null
                if ($ads) {
                    $ads | ForEach-Object { Write-Host "  - $_" }
                }
                else {
                    Write-Warning "Could not fetch ADs via OCI CLI"
                }
            }
        }
        catch {
            Write-Warning "Could not parse tenancy OCID from terraform.tfvars"
        }
    }
    else {
        Write-Warning "OCI CLI not available or terraform.tfvars missing"
        Write-Host "Common ADs for us-ashburn-1:"
        Write-Host "  - mcUX:US-ASHBURN-AD-1"
        Write-Host "  - mcUX:US-ASHBURN-AD-2"
        Write-Host "  - mcUX:US-ASHBURN-AD-3"
    }
}

# Main execution
function Main {
    Write-Host ""
    
    $terraformOk = Test-Terraform
    if (-not $terraformOk) {
        return
    }
    
    Write-Host ""
    Test-OciConfig
    
    Write-Host ""
    Test-TfVars
    
    Write-Host ""
    Test-DeploymentState
    
    Write-Host ""
    Show-AvailabilityDomains
    
    Write-Host ""
    Show-RecoveryActions
    
    Write-Host ""
    Write-Success "Troubleshooting complete!"
    
    if ($Detailed) {
        Write-Host ""
        Write-Status "Additional debugging commands:"
        Write-Host "  terraform show" -ForegroundColor Gray
        Write-Host "  terraform validate" -ForegroundColor Gray
        Write-Host "  terraform plan -detailed-exitcode" -ForegroundColor Gray
        Write-Host "  terraform version" -ForegroundColor Gray
    }
}

# Run main function
Main