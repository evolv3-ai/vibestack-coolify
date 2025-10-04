# VibeStack Coolify Deployment Workflow Flowchart

```mermaid
flowchart TD
    A[User clicks Deploy to Oracle Cloud] --> B[Infrastructure Provisioning]

    subgraph B[Infrastructure Provisioning - Terraform]
        B1[Create Compartment]
        B2[Create VCN & Subnets]
        B3[Create Security Lists]
        B4[Create Internet Gateway]
        B5[Create Compute Instance]
        B6[Attach Block Volume]

        B1 --> B2 --> B3 --> B4 --> B5 --> B6
    end

    B --> C[Server Bootstrap]

    subgraph C[Server Bootstrap - Cloud-init]
        C1[Configure DNS Nameservers]
        C2[Install Base Packages]
        C3[Download Ansible Playbook]
        C4[Install Ansible & Docker]
        C5[Execute Ansible Playbook]

        C1 --> C2 --> C3 --> C4 --> C5
    end

    C --> D[Coolify Installation]

    subgraph D[Coolify Installation - Ansible]
        D1[Update System Packages]
        D2[Install Docker & Compose]
        D3[Check Existing Coolify]
        D4[Run Coolify Installer]
        D5[Configure SSL Certificates]
        D6[Set Root User Credentials]

        D1 --> D2 --> D3 --> D4
        D4 --> D5
        D5 --> D6
    end

    D --> E{Cloudflare Tunnel Enabled?}

    E -->|Yes| F[Cloudflare Tunnel Setup]

    subgraph F[Cloudflare Tunnel Setup - Ansible]
        F1[Install cloudflared]
        F2[Create Cloudflare Tunnel]
        F3[Configure Tunnel Settings]
        F4[Create DNS Records]
        F5[Start Tunnel Service]

        F1 --> F2 --> F3 --> F4 --> F5
    end

    E -->|No| G[Post-Deployment Configuration]

    F --> G[Post-Deployment Configuration]

    subgraph G[Post-Deployment Configuration]
        G1[Configure Domains in Database]
        G2[Save Deployment Info]
        G3[Generate Access Credentials]

        G1 --> G2 --> G3
    end

    G --> H[Deployment Complete]

    H --> I[Coolify Ready for Use]
```

## Workflow Overview

This flowchart represents the complete VibeStack Coolify deployment workflow, which consists of four main phases:

1. **Infrastructure Provisioning**: Uses Terraform to create Oracle Cloud resources
2. **Server Bootstrap**: Uses cloud-init to prepare the Ubuntu server
3. **Coolify Installation**: Uses Ansible to install and configure Coolify
4. **Post-Deployment Configuration**: Final setup and credential generation

The workflow includes an optional Cloudflare Tunnel setup phase that runs conditionally based on user configuration.

## Key Decision Points

- **SSL Certificates**: Optional SSL certificate deployment from Cloudflare Origin certificates
- **Cloudflare Tunnel**: Optional secure tunnel setup for HTTPS access without public IP exposure

## Files Involved

- `schema.yaml`: Configuration schema and variable definitions
- `cloud-init-coolify.yaml`: Server bootstrap script
- `coolify-complete-setup.yml`: Ansible playbook for installation and configuration
- Terraform files: Infrastructure provisioning (`*.tf` files)