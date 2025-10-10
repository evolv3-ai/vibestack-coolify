# OCI Capacity Checking Guide

This guide explains how to check and monitor Oracle Cloud Infrastructure (OCI) Always Free tier A1 Flex capacity before deploying Coolify.

## Overview

OCI Always Free tier A1 instances frequently experience capacity constraints, especially in popular regions. This repository includes capacity checking tools to prevent failed deployments and wasted time.

## Automatic Capacity Checking (Recommended)

By default, Terraform automatically checks capacity before deployment when you use the "Deploy to Oracle Cloud" button.

### How It Works

1. **Form Configuration**: When you fill out the OCI Resource Manager form, specify your desired OCPUs and memory (2/12 or 4/24)
2. **Automatic Check**: Terraform checks all availability domains in your region for available capacity
3. **Deployment Decision**:
   - ✅ **Capacity Available**: Deployment proceeds automatically using the AD with available capacity
   - ❌ **No Capacity**: Deployment fails gracefully with helpful error message (no orphaned resources)

### Disabling Capacity Check

If you want to skip the capacity check (not recommended):

1. In the OCI Resource Manager form, find "Check capacity before deployment"
2. Uncheck the box
3. Proceed with deployment (may fail if no capacity available)

## Manual Capacity Checking

For users deploying with Terraform locally or wanting to check capacity before creating a stack:

### One-Time Capacity Check

```bash
# Extract deployment package
unzip vibestack-coolify.zip
cd vibestack-coolify

# Check capacity (default: 4 OCPUs, 24GB RAM)
./scripts/check-oci-capacity.sh

# Check smaller configuration (2 OCPUs, 12GB RAM)
./scripts/check-oci-capacity.sh --ocpus 2 --memory-gb 12

# Check specific region
./scripts/check-oci-capacity.sh --region us-ashburn-1
```

**Example Output (Capacity Available):**
```
╔═══════════════════════════════════════════════════════════════════════════╗
║         OCI Always Free Tier A1 Flex Capacity Check                      ║
╚═══════════════════════════════════════════════════════════════════════════╝

Region: ca-montreal-1
Configuration: 4 OCPUs, 24GB RAM

✓ Found 1 availability domain(s) to check

═══════════════════════════════════════════════════════════════════════════
  Checking Capacity: 4 OCPUs, 24GB RAM
═══════════════════════════════════════════════════════════════════════════

Checking: IOlJ:CA-MONTREAL-1-AD-1
  Shape: VM.Standard.A1.Flex
  Config: 4 OCPUs, 24GB RAM
  ✓ AVAILABLE

═══════════════════════════════════════════════════════════════════════════
  SUMMARY
═══════════════════════════════════════════════════════════════════════════

✓ Capacity Available!

  Availability Domain: IOlJ:CA-MONTREAL-1-AD-1

  You can deploy to this AD.
```

**Example Output (No Capacity):**
```
═══════════════════════════════════════════════════════════════════════════
  SUMMARY
═══════════════════════════════════════════════════════════════════════════

✗ No capacity available in any availability domain.

  Checked: 1 AD(s) in region ca-montreal-1
  Configuration: 4 OCPUs, 24GB RAM

  Options:
    1. Try again later (capacity changes frequently)
    2. Try a different region
    3. Try a smaller configuration (2 OCPUs, 12GB RAM)
    4. Use the monitoring script for automated retry:
       ./scripts/monitor-and-deploy.sh --stack-id <STACK_OCID>
```

## Automated Capacity Monitoring

For regions with frequent capacity constraints, use the monitoring script to automatically deploy when capacity becomes available.

### Prerequisites

1. Create your stack in OCI Resource Manager
2. Get the stack OCID from the stack details page
3. Extract the deployment package with scripts

### Basic Usage

```bash
# Monitor and auto-deploy when capacity found (checks every 5 minutes)
./scripts/monitor-and-deploy.sh --stack-id ocid1.ormstack.oc1.ca-montreal-1.xxxxx
```

### Advanced Usage

```bash
# Custom check interval (3 minutes = 180 seconds)
./scripts/monitor-and-deploy.sh \
  --stack-id ocid1.ormstack.oc1.ca-montreal-1.xxxxx \
  --interval 180

# Check for smaller configuration
./scripts/monitor-and-deploy.sh \
  --stack-id ocid1.ormstack.oc1.ca-montreal-1.xxxxx \
  --ocpus 2 \
  --memory-gb 12

# Limited attempts (100 checks = ~8 hours with 5min interval)
./scripts/monitor-and-deploy.sh \
  --stack-id ocid1.ormstack.oc1.ca-montreal-1.xxxxx \
  --max-attempts 100

# Custom region
./scripts/monitor-and-deploy.sh \
  --stack-id ocid1.ormstack.oc1.ca-montreal-1.xxxxx \
  --region us-ashburn-1

# Notification on success
./scripts/monitor-and-deploy.sh \
  --stack-id ocid1.ormstack.oc1.ca-montreal-1.xxxxx \
  --notify-command "echo 'Deployment started!' | mail -s 'OCI Deploy' you@example.com"
```

### Example Output

```
╔═══════════════════════════════════════════════════════════════════════════╗
║         OCI Capacity Monitor and Auto-Deploy                             ║
╚═══════════════════════════════════════════════════════════════════════════╝

Configuration:
  Stack ID:        ocid1.ormstack.oc1.ca-montreal-1.xxxxx
  Check interval:  300s (5 minutes)
  Target capacity: 4 OCPUs, 24GB RAM
  Max attempts:    unlimited

✓ Stack: vibestack-coolify-20241009
✓ Region: ca-montreal-1
✓ Found 1 availability domain(s) to monitor

═══════════════════════════════════════════════════════════════════════════
Starting capacity monitoring...
═══════════════════════════════════════════════════════════════════════════

[Attempt 1 - 2025-10-09 14:30:00 - Elapsed: 0m]
  Checking IOlJ:CA-MONTREAL-1-AD-1... ✗ No capacity
  ⏳ Waiting 300s until next check...

[Attempt 2 - 2025-10-09 14:35:00 - Elapsed: 5m]
  Checking IOlJ:CA-MONTREAL-1-AD-1... ✓ AVAILABLE

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SUCCESS! Capacity found in: IOlJ:CA-MONTREAL-1-AD-1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Creating apply job for stack...
✓ Apply job created: ocid1.ormjob.oc1.ca-montreal-1.xxxxx

Stack deployment initiated successfully!

Monitor job progress with:
  oci resource-manager job get --job-id ocid1.ormjob.oc1.ca-montreal-1.xxxxx
```

## Understanding Capacity Availability

### Capacity Status Values

- **✓ AVAILABLE**: Capacity exists, can deploy immediately
- **✗ OUT OF CAPACITY**: No capacity available in this AD
- **⚠ CONSTRAINT ERROR**: Invalid OCPU/memory configuration

### Always Free Tier Limits

**Per Tenancy (Home Region Only):**
- 4 OCPUs total (VM.Standard.A1.Flex)
- 24 GB RAM total
- 200 GB block storage total

**Coolify Configurations:**
- **Full Tier**: 4 OCPUs, 24GB RAM, 100GB storage (uses 100% of CPU/RAM quota)
- **Half Tier**: 2 OCPUs, 12GB RAM, 100GB storage (uses 50% of CPU/RAM quota)

### Regions with Better Availability

Capacity varies by region. Generally, newer regions have better availability:

**Often Available:**
- ca-montreal-1 (Canada - Montreal)
- sa-saopaulo-1 (Brazil - São Paulo)
- ap-singapore-1 (Singapore)

**Often Constrained:**
- us-ashburn-1 (US East - Virginia)
- us-phoenix-1 (US West - Arizona)
- uk-london-1 (UK - London)

**Note**: This changes frequently. Always check current capacity.

## Troubleshooting

### Error: "Unable to retrieve tenancy OCID"

**Cause**: OCI CLI not configured or missing permissions

**Solution**:
1. Verify OCI CLI is installed: `oci --version`
2. Configure OCI CLI: `oci setup config`
3. Verify credentials: `oci iam region list`

### Error: "No availability domains found"

**Cause**: Invalid region or not subscribed to region

**Solution**:
1. Check region subscription: `oci iam region-subscription list`
2. Subscribe to region in OCI Console
3. Verify region name format (e.g., `us-ashburn-1`, not `us-ashburn`)

### Capacity Check Takes Too Long

**Cause**: Checking multiple availability domains

**Solution**:
- Each AD check takes ~2-3 seconds
- Script stops at first available AD
- Most regions have 1-3 ADs
- Total check time: 2-9 seconds typically

### Monitor Script Not Finding Capacity

**Options**:
1. Increase check frequency: `--interval 180` (3 minutes)
2. Try different region: `--region us-phoenix-1`
3. Try smaller config: `--ocpus 2 --memory-gb 12`
4. Check during off-peak hours (late night in region's timezone)

### Deployment Fails Despite Capacity Check Passing

**Cause**: Capacity changed between check and deployment

**Solution**:
- Capacity changes frequently
- Time gap between check and resource creation
- Use monitoring script for immediate deployment when capacity found
- Re-run capacity check and try again

## Best Practices

1. **Enable Capacity Check**: Keep the automatic capacity check enabled in OCI Resource Manager
2. **Use Monitoring Script**: For capacity-constrained regions, use the monitoring script
3. **Try Multiple Regions**: Check capacity in several regions if flexible on location
4. **Off-Peak Deployment**: Try deploying during off-peak hours (late night in region's timezone)
5. **Smaller Configuration First**: Deploy 2 OCPUs/12GB first, upgrade later if needed
6. **Be Patient**: A1 capacity becomes available frequently, usually within hours

## Script Reference

### check-oci-capacity.sh

**Purpose**: One-time capacity check across all availability domains

**Options**:
- `--region REGION`: OCI region to check (default: home region)
- `--ocpus NUM`: OCPUs to check for (default: 4)
- `--memory-gb NUM`: Memory in GB (default: 24)
- `--json-output`: Output JSON for Terraform integration
- `--help`: Show help message

**Exit Codes**:
- `0`: Capacity available
- `1`: No capacity available
- Other: Error occurred

### monitor-and-deploy.sh

**Purpose**: Continuous monitoring with automatic deployment

**Required Options**:
- `--stack-id OCID`: OCI Resource Manager stack OCID

**Optional Options**:
- `--interval SECONDS`: Check interval (default: 300)
- `--region REGION`: Region to check (default: stack's region)
- `--ocpus NUM`: OCPUs to check (default: 4)
- `--memory-gb NUM`: Memory in GB (default: 24)
- `--max-attempts NUM`: Maximum attempts (default: unlimited)
- `--notify-command CMD`: Command to run on success

**Exit Codes**:
- `0`: Capacity found and deployment started
- `1`: Max attempts reached or error occurred

## Additional Resources

- [OCI Always Free Tier Documentation](https://www.oracle.com/cloud/free/)
- [OCI Compute Shapes](https://docs.oracle.com/en-us/iaas/Content/Compute/References/computeshapes.htm)
- [OCI Region Availability](https://www.oracle.com/cloud/data-regions/)
- [OCI CLI Reference](https://docs.oracle.com/en-us/iaas/tools/oci-cli/latest/oci_cli_docs/)

## Support

For issues or questions:

1. Check [GitHub Issues](https://github.com/evolv3-ai/vibestack-coolify/issues)
2. Review [README.md](../README.md) for deployment instructions
3. Check [CLAUDE.md](../CLAUDE.md) for development guidance
