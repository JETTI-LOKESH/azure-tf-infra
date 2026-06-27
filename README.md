# Azure Infrastructure Deployment

Production-grade infrastructure deployment on Azure using Terraform IaC.

## Architecture

```
┌─────────────────────────────────────────────────┐
│                  Resource Group                   │
│                                                   │
│  ┌─────────────────────────────────────────┐     │
│  │           Virtual Network (10.0.0.0/16)  │     │
│  │                                           │     │
│  │  ┌─────────────┐    ┌─────────────────┐  │     │
│  │  │  Subnet A    │    │   Subnet B       │  │     │
│  │  │ 10.0.1.0/24 │    │  10.0.2.0/24     │  │     │
│  │  │  (App)       │    │  (Reserved)      │  │     │
│  │  │  ┌────────┐  │    │                  │  │     │
│  │  │  │Linux VM│  │    │                  │  │     │
│  │  │  │(HTTPS) │  │    │                  │  │     │
│  │  │  └────────┘  │    │                  │  │     │
│  │  └──────┬───────┘    └──────────────────┘  │     │
│  │         │ NSG                               │     │
│  └─────────┼───────────────────────────────────┘     │
│            │                                          │
│  ┌─────────┴─────────┐    ┌──────────────────┐      │
│  │   Public IP         │    │   Key Vault       │      │
│  │   (HTTPS:443)       │    │   (Secrets)       │      │
│  └─────────────────────┘    └──────────────────┘      │
│                                                        │
│  ┌────────────────────────────────────────────┐       │
│  │         Azure Monitor (Alerts)              │       │
│  └────────────────────────────────────────────┘       │
└────────────────────────────────────────────────────────┘
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.50.0
- Azure subscription (free trial works)
- Git

## Quick Start

### 1. Authenticate with Azure

```bash
az login
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"
```

### 2. Initialize Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
```

### 3. Plan and Apply

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

### 4. Verify Deployment

```bash
# Get the public IP from Terraform output
terraform output public_ip_address

# Test HTTPS service
curl -k https://$(terraform output -raw public_ip_address)
```

## Cleanup

```bash
terraform destroy
```

## Repository Structure

```
├── README.md                          # This file
├── terraform/
│   ├── main.tf                        # Root module (calls child modules)
│   ├── variables.tf                   # Input variables
│   ├── outputs.tf                     # Output values
│   ├── providers.tf                   # Provider configuration
│   ├── terraform.tfvars.example       # Example variable values
│   └── modules/
│       ├── networking/                # VNet, subnets, NSG
│       ├── compute/                   # VM, NIC, Public IP, SSH key
│       ├── keyvault/                  # Key Vault, access policies, secrets
│       └── monitoring/                # Log Analytics, alerts, diagnostics
├── scripts/
│   ├── startup.sh                     # VM startup script (HTTPS service)
│   └── bootstrap-backend.sh           # (Optional) Setup remote state backend
├── .github/
│   └── workflows/
│       └── terraform.yml              # CI/CD pipeline
└── docs/
    ├── RUNBOOK.md                     # Operational runbook
    ├── MONITORING.md                  # Monitoring and alerting notes
    └── AI_USAGE.md                    # AI tools usage note
```

## Security Notes

- NSG rules restrict inbound traffic to HTTPS (443) and SSH (22) only
- SSH access is restricted to a configurable CIDR range
- Key Vault uses access policies with least-privilege (VM gets read-only, deployer gets manage)
- No secrets are hardcoded; all sensitive values come from variables or Key Vault
- VM uses managed identity for Key Vault access
- CI/CD uses OIDC federation (no stored credentials)

## Cost Estimate (Free Trial)

| Resource | Monthly Cost |
|----------|-------------|
| D2s_v3 Linux VM | ~$70 (within $200 credit) |
| Virtual Network | Free |
| NSG | Free |
| Key Vault (10K ops) | Free |
| Public IP (Standard) | ~$4 |
| Log Analytics (5GB free) | Free |
| Monitor Alert Rules (x2) | ~$0.20 |
| **Total** | **~$75/month** |
