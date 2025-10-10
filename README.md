# VibeStack Coolify - OCI Always Free Deployment

Deploy Coolify on Oracle Cloud Infrastructure using only Always Free tier resources.

| [Available Now: `VibeStack Coolify`](#vibestack-coolify) | [Coming Soon: Additional Options](#coming-soon) |
|---|---|
| Deploy Coolify using half of your Always Free allocation. <br/><br/> **Coolify**: Self-hosted app platform (like Vercel/Netlify) <br/> • 2 OCPUs, 12GB RAM, 100GB storage <br/> • Perfect for developers wanting their own PaaS | **COMING SOON!** <br/><br/> • **VibeStack KASM**: Remote workspace server <br/> • **VibeStack Full**: Complete deployment with both servers <br/> • Additional deployment options |
| **VibeStack Coolify:**
 [![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/evolv3-ai/vibestack-coolify/releases/latest/download/vibestack-coolify.zip) | **Stay tuned for more deployment options!** |

```text
vibestack-coolify
├── deploy/
│   └── coolify/            # VibeStack Coolify deployment
└── docs/                   # Documentation (COMING SOON)
```

[oci]: https://cloud.oracle.com

## VibeStack Coolify

Deploy a single Coolify server using half of your Always Free allocation, keeping the other half available for other uses.

- **What**: Self-hosted application deployment platform (like Vercel/Netlify/Heroku)
- **Resources**: VM.Standard.A1.Flex (2 OCPUs, 12GB RAM, 100GB storage)
- **Perfect for**: Developers wanting their own PaaS for deploying Docker containers, static sites, and databases
- **Ports**: 22 (SSH), 80/443 (HTTP/S), 8000 (Coolify Web Interface)

## Coming Soon

Additional deployment options will be available in future releases:

- **VibeStack KASM**: Browser-based remote workspace server with containerized desktops
- **VibeStack Full**: Complete deployment with both KASM and Coolify servers using your full Always Free allocation

## 🔧 All Packages Include

- **Custom compartment** (you name it during deployment)
- **Ubuntu 22.04 LTS** (or Oracle Linux option)
- **Public networking** with security groups
- **SSH access** with your public key
- **Always Free tier compatible** - no charges

## 🔧 Post-Deployment Tools

Post-deployment management tools will be available in future releases:

- SSH client import file generation (COMING SOON)
- Deployment log management (COMING SOON)
- Automated setup scripts (COMING SOON)

## ⚠️ Prerequisites

Before deploying, you **MUST** ensure these critical configuration items are ready:

### 1. Check Capacity Availability

A1 Flex capacity is often constrained. **Check capacity before starting deployment**:

```bash
# Download the deployment package from the latest release
unzip vibestack-coolify.zip
cd vibestack-coolify

# Check capacity in your target region
./scripts/check-oci-capacity.sh

# For smaller configuration (2 OCPUs, 12GB RAM)
./scripts/check-oci-capacity.sh --ocpus 2 --memory-gb 12
```

Note the availability domain that shows as **AVAILABLE** - you'll need this during deployment.

### 2. Required Configuration Variables

When creating the stack in OCI Resource Manager, the following variables **MUST** be set correctly:

| Variable | Value | Purpose |
|----------|-------|---------|
| `deploy_coolify` | `true` | Deploy Coolify server (critical!) |
| `coolify_ocpus` | `2` or `4` | OCPUs for Coolify (1-4 max) |
| `coolify_memory_in_gbs` | `12` or `24` | RAM for Coolify (1-24 max) |
| `availability_domain` | From capacity check | AD with available capacity |
| `coolify_root_user_email` | Your email | Coolify admin email |
| `ssh_authorized_keys` | Your SSH public key | Server access |

**IMPORTANT**: If these variables are not set correctly, deployment will create network resources but **fail to create the Coolify instance**, leaving orphaned resources.

### 3. Verify OCI Credentials

Ensure you're logged into Oracle Cloud and have proper permissions:

```bash
# If using OCI CLI locally (not Resource Manager)
oci iam region list
```

## 🚀 Setup Steps

Follow these steps to deploy VibeStack Coolify:

1. **Create a free tier account with Oracle Cloud** at [cloud.oracle.com](https://cloud.oracle.com)
2. **Create an ED25519 SSH key** (newbies can use [Termius](https://termius.com/))
3. **Create a free Cloudflare account** at [cloudflare.com](https://cloudflare.com)
4. **Create a free Zero Trust Cloudflare account** (for tunnels) at [one.dash.cloudflare.com](https://one.dash.cloudflare.com)
5. **Set up your domain**: Either purchase a domain with Cloudflare or transfer an existing domain to Cloudflare to use for your Coolify wildcard domain
6. **Create an origin certificate and key** for your Coolify wildcard domain in Cloudflare
7. **Log into your Oracle account** at [cloud.oracle.com](https://cloud.oracle.com)
8. **Click on the "Deploy to Oracle" button** above and enter your options/keys on the deployment form

## ⚡ Capacity Checking

OCI Always Free A1 instances often experience capacity constraints. This deployment includes **automatic capacity checking** to prevent failed deployments.

### How It Works

- **Automatic**: When you click "Deploy to Oracle Cloud", Terraform automatically checks all availability domains for capacity
- **Smart Selection**: Uses the availability domain with available capacity for your chosen configuration
- **Graceful Failure**: If no capacity is available, deployment fails cleanly with helpful guidance (no orphaned resources)
- **Configurable**: Check capacity for 2/12 or 4/24 OCPU/RAM configurations based on your form selections

### If Capacity Is Unavailable

When deployment fails due to capacity constraints, you have several options:

1. **Try Again Later**: Capacity changes frequently (often within hours)
2. **Use Monitoring Script**: Automatically deploy when capacity becomes available
   - Download and extract the deployment package from the GitHub release
   - Run: `./scripts/monitor-and-deploy.sh --stack-id <YOUR_STACK_OCID>`
   - Script checks every 5 minutes and auto-deploys when capacity is found
3. **Try Different Region**: Some regions have better availability than others
4. **Try Smaller Configuration**: 2 OCPUs/12GB RAM has better availability than 4 OCPUs/24GB RAM
5. **Disable Check**: Uncheck "Check capacity before deployment" (not recommended)

### Manual Capacity Check

Want to check capacity before creating a stack? Download the package and run:

```bash
# Extract deployment package
unzip vibestack-coolify.zip
cd vibestack-coolify

# Check capacity (default: 4 OCPUs, 24GB RAM)
./scripts/check-oci-capacity.sh

# Check smaller configuration
./scripts/check-oci-capacity.sh --ocpus 2 --memory-gb 12
```

For complete documentation, see [docs/capacity-checking-guide.md](docs/capacity-checking-guide.md)

## 🔧 Troubleshooting

### Issue: Deployment Fails But Creates Network Resources

**Symptoms**:
- Deployment job shows `FAILED` status
- VCN, subnets, security lists are created
- **No Coolify compute instance** is created
- Error message: `TERRAFORM_EXECUTION_ERROR`

**Root Cause**: Missing or incorrect required variables in stack configuration.

**Solution**:

1. **Check your stack variables** (OCI Console → Resource Manager → Stack → Variables):
   ```bash
   # Or use OCI CLI to verify
   oci resource-manager stack get --stack-id <YOUR_STACK_OCID> \
     --query 'data.variables'
   ```

2. **Verify these critical variables are set**:
   - `deploy_coolify = true`
   - `coolify_ocpus = 2` (or 4)
   - `coolify_memory_in_gbs = 12` (or 24)
   - `availability_domain = "qkyj:US-ASHBURN-AD-1"` (or your AD with capacity)

3. **Update stack variables** if missing:
   ```bash
   oci resource-manager stack update \
     --stack-id <YOUR_STACK_OCID> \
     --variables '{
       "deploy_coolify": "true",
       "coolify_ocpus": "2",
       "coolify_memory_in_gbs": "12",
       "availability_domain": "YOUR-AD-WITH-CAPACITY"
     }'
   ```

4. **Clean up orphaned resources**:
   - Go to OCI Console → Resource Manager → Your Stack
   - Click "Destroy" to remove orphaned network resources
   - Wait for destroy to complete

5. **Re-deploy with correct variables**:
   - Click "Apply" with properly configured variables
   - Or create a new stack with all required variables set

### Issue: Capacity Not Available

**Symptoms**:
- Deployment fails with message about `OUT_OF_HOST_CAPACITY`
- Capacity check shows no available ADs

**Solutions**:

1. **Try again later** (capacity changes frequently, often within hours)
2. **Use the monitoring script** for automated retry:
   ```bash
   ./scripts/monitor-and-deploy.sh --stack-id <YOUR_STACK_OCID>
   ```
3. **Try a different region** in OCI
4. **Try smaller configuration** (2 OCPUs, 12GB instead of 4 OCPUs, 24GB)

### Issue: Terraform Validation Errors

**Symptoms**:
- Error: "At least one of deploy_coolify or deploy_kasm must be true"
- Error: "Total OCPUs exceeds Always Free limit of 4"
- Error: "Total memory exceeds Always Free limit of 24GB"

**Solution**: These are validation checks ensuring your configuration is valid. Review the error message and adjust your variables accordingly. For this Coolify-only package, `deploy_coolify` must be `true`.

### Getting Help

If issues persist:
1. Check [deployment-failure.md](deployment-failure.md) for detailed troubleshooting
2. Review Terraform state to see which resources were created
3. Open an issue at [github.com/evolv3-ai/vibestack-coolify/issues](https://github.com/evolv3-ai/vibestack-coolify/issues)

## 💡 Why VibeStack Coolify?

- **Always Free**: Uses Oracle Cloud's generous Always Free tier
- **Self-Hosted**: Your own application deployment platform
- **Compartmentalized**: Clean organization with custom naming
- **Ubuntu**: Modern, well-supported OS with excellent ARM compatibility
- **One-Click**: Deploy button makes it trivial to get started

## 🔗 Related Projects

- [Coolify](https://coolify.io/) - Self-hosted app deployment platform
- [Oracle Cloud Always Free](https://www.oracle.com/cloud/free/) - Generous free tier

## 📄 License

Released under the Universal Permissive License v1.0