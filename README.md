# VibeStack Coolify - OCI Always Free Deployment

Deploy Coolify on Oracle Cloud Infrastructure using only Always Free tier resources.

| [Available Now: `VibeStack Coolify`](#vibestack-coolify) | [Coming Soon: Additional Options](#coming-soon) |
|---|---|
| Deploy Coolify using half of your Always Free allocation. <br/><br/> **Coolify**: Self-hosted app platform (like Vercel/Netlify) <br/> • 2 OCPUs, 12GB RAM, 100GB storage <br/> • Perfect for developers wanting their own PaaS | **COMING SOON!** <br/><br/> • **VibeStack KASM**: Remote workspace server <br/> • **VibeStack Full**: Complete deployment with both servers <br/> • Additional deployment options |
| **VibeStack Coolify:**
 [![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/your-org/vibestack-coolify/releases/latest/download/vibestack-coolify.zip) | **Stay tuned for more deployment options!** |

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