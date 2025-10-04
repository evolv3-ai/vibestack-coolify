# Quick Fix Script for OCI 500 Internal Server Error
# Run this script to attempt common fixes for deployment failures

param(
    [switch]$Force,
    [string]$AvailabilityDomain = ""
)

Write-Host "🚀 Coolify OCI Quick Fix Script" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

function Write-Step {
    param($Step, $Message)
    Write-Host "[$Step] $Message" -ForegroundColor Yellow
}

function Write-Success {
    param($Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
    param($Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

# Step 1: Update provider
Write-Step "1/5" "Updating Terraform provider to latest version..."
try {
    terraform init -upgrade
    Write-Success "Provider updated successfully"
}
catch {
    Write-Error "Failed to update provider: $_"
}

# Step 2: Validate configuration
Write-Step "2/5" "Validating Terraform configuration..."
try {
    terraform validate
    Write-Success "Configuration is valid"
}
catch {
    Write-Error "Configuration validation failed: $_"
    exit 1
}

# Step 3: Set alternative availability domain if provided
if ($AvailabilityDomain) {
    Write-Step "3/5" "Setting availability domain to $AvailabilityDomain..."
    
    if (Test-Path "terraform.tfvars") {
        $content = Get-Content "terraform.tfvars"
        $newContent = $content | Where-Object { $_ -notmatch "^availability_domain" }
        $newContent += "availability_domain = `"$AvailabilityDomain`""
        $newContent | Set-Content "terraform.tfvars"
        Write-Success "Availability domain updated"
    }
    else {
        Write-Error "terraform.tfvars not found"
    }
}
else {
    Write-Step "3/5" "Skipping availability domain change (not specified)"
}

# Step 4: Clean failed resources if Force is specified
if ($Force) {
    Write-Step "4/5" "Removing failed instance resource..."
    try {
        terraform destroy -target=oci_core_instance.coolify -auto-approve
        Write-Success "Failed resources cleaned"
    }
    catch {
        Write-Warning "Could not clean resources (may not exist): $_"
    }
}
else {
    Write-Step "4/5" "Skipping resource cleanup (use -Force to enable)"
}

# Step 5: Retry deployment
Write-Step "5/5" "Attempting deployment..."
try {
    terraform apply -auto-approve
    Write-Success "Deployment completed successfully!"
    
    Write-Host ""
    Write-Host "🎉 Deployment Fixed!" -ForegroundColor Green
    Write-Host "Check the outputs for your Coolify server details." -ForegroundColor Cyan
}
catch {
    Write-Error "Deployment still failing: $_"
    Write-Host ""
    Write-Host "📋 Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Try a different availability domain:"
    Write-Host "   .\quick-fix.ps1 -AvailabilityDomain 'mcUX:US-ASHBURN-AD-2'"
    Write-Host ""
    Write-Host "2. Force clean and retry:"
    Write-Host "   .\quick-fix.ps1 -Force"
    Write-Host ""
    Write-Host "3. Run full troubleshooting:"
    Write-Host "   .\troubleshoot-deployment.ps1"
    Write-Host ""
    Write-Host "4. Check OCI service status:"
    Write-Host "   https://ocistatus.oraclecloud.com/"
}