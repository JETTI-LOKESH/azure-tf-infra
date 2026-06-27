terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Remote backend (recommended for production/team use)
  # To enable: run scripts/bootstrap-backend.sh first, then uncomment below
  # and run: terraform init -migrate-state
  #
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "<created-by-bootstrap>"
  #   container_name       = "tfstate"
  #   key                  = "infra-assessment.tfstate"
  # }
}

# Authentication strategy:
# - Local development: Azure CLI (az login) — no credentials in code
# - CI/CD pipeline: OIDC federated credentials (no stored secrets)
# - Production: Managed Identity or OIDC
# The provider block has no auth config, so Terraform uses the Azure CLI token
# automatically. For CI/CD, the GitHub Actions workflow sets environment variables
# (ARM_CLIENT_ID, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID) via OIDC.
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}
