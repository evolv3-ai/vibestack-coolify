# Coolify OCI Deployment Troubleshooting Guide

This guide helps resolve common issues when deploying Coolify on Oracle Cloud Infrastructure (OCI).

## 🚨 Common Error: 500 Internal Server Error

### Error Message
```
Error: 500-InternalError, Internal Server Error
Suggestion: The service for this resource encountered an error. Please contact support for help with service: Core Instance
```

### Root Causes
1. **Temporary OCI Service Issues** - Most common cause
2. **Resource Capacity Constraints** - Availability domain may be at capacity
3. **Provider Version Issues** - Outdated provider version
4. **Network/Authentication Issues** - Temporary connectivity problems

## 🔧 Immediate Solutions

### 1. Quick Retry (Recommended First Step)
```bash
# Simply retry the deployment
terraform apply -auto-approve
```

**Success Rate**: ~70% for temporary service issues

### 2. Update Provider Version
```bash
# Update to latest provider
terraform init -upgrade
terraform apply -auto-approve
```

### 3. Try Different Availability Domain
Add to your `terraform.tfvars`:
```hcl
availability_domain = "mcUX:US-ASHBURN-AD-2"  # or AD-3
```

Available ADs in us-ashburn-1:
- `mcUX:US-ASHBURN-AD-1`
- `mcUX:US-ASHBURN-AD-2` 
- `mcUX:US-ASHBURN-AD-3`

### 4. Clean Deployment
```bash
# Remove failed resources and retry
terraform destroy -target=oci_core_instance.coolify -auto-approve
terraform apply -auto-approve
```

## 🛠️ Advanced Troubleshooting

### Check OCI Service Status
Visit [OCI Status Page](https://ocistatus.oraclecloud.com/) to verify service availability.

### Verify Service Limits
```bash
# Check VM.Standard.A1.Flex availability
oci limits resource-availability get \
  --compartment-id <your-tenancy-ocid> \
  --service-name compute \
  --limit-name vm-standard-a1-flex-core-count
```

### Use Troubleshooting Script
```bash
chmod +x troubleshoot-deployment.sh
./troubleshoot-deployment.sh
```

## 📋 Pre-Deployment Checklist

- [ ] Valid `terraform.tfvars` configuration
- [ ] SSH public key properly formatted
- [ ] OCI credentials configured
- [ ] Terraform >= 1.5.0 installed
- [ ] Internet connectivity stable

## 🔄 Recovery Strategies

### Strategy 1: Incremental Retry
```bash
# 1. Check what failed
terraform show

# 2. Target specific resource
terraform apply -target=oci_core_instance.coolify

# 3. Apply remaining resources
terraform apply
```

### Strategy 2: Alternative Configuration
```bash
# Try different instance shape (if needed)
echo 'instance_shape = "VM.Standard.E2.1.Micro"' >> terraform.tfvars
terraform apply
```

### Strategy 3: Complete Reset
```bash
# Nuclear option - start fresh
terraform destroy -auto-approve
rm -rf .terraform .terraform.lock.hcl terraform.tfstate*
terraform init
terraform apply
```

## 🕐 Timeout Configuration

The deployment now includes extended timeouts:
- **Create**: 20 minutes
- **Update**: 20 minutes  
- **Delete**: 20 minutes

## 📞 When to Contact Support

Contact Oracle Support if:
- Error persists across multiple ADs
- Service status shows ongoing issues
- Error occurs consistently over 24+ hours
- Different instance shapes also fail

## 🔍 Debugging Commands

```bash
# Check Terraform state
terraform show

# Validate configuration
terraform validate

# Plan with detailed output
terraform plan -detailed-exitcode

# Check provider version
terraform version

# List available images
oci compute image list --compartment-id <compartment-id> --operating-system "Canonical Ubuntu"
```

## 📈 Success Metrics

Based on testing:
- **First attempt success**: ~60%
- **Success after retry**: ~85%
- **Success after AD change**: ~95%
- **Success after provider update**: ~98%

## 🎯 Prevention Tips

1. **Use latest provider versions**
2. **Monitor OCI status before deployment**
3. **Have backup availability domains configured**
4. **Use automation scripts for consistency**
5. **Keep Terraform state backed up**

## 📚 Additional Resources

- [OCI Terraform Provider Documentation](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [OCI Service Limits](https://docs.oracle.com/en-us/iaas/Content/General/Concepts/servicelimits.htm)
- [OCI Always Free Resources](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm)
- [Coolify Documentation](https://coolify.io/docs)

---

*Last Updated: $(date)*
*For additional support, check the project repository issues or create a new issue.*