#!/bin/bash
# Bootstrap script: Creates the Azure Storage Account for Terraform remote state
# Run this ONCE before enabling the remote backend in providers.tf
#
# Usage: ./bootstrap-backend.sh

set -euo pipefail

RESOURCE_GROUP="rg-terraform-state"
STORAGE_ACCOUNT="stterraformstate$(openssl rand -hex 4)"
CONTAINER_NAME="tfstate"
LOCATION="swedencentral"

echo "Creating resource group for Terraform state..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none

echo "Creating storage account: $STORAGE_ACCOUNT"
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --encryption-services blob \
  --output none

echo "Creating blob container: $CONTAINER_NAME"
az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STORAGE_ACCOUNT" \
  --output none

echo ""
echo "=== Backend Configuration ==="
echo "Update terraform/providers.tf with:"
echo ""
echo "  backend \"azurerm\" {"
echo "    resource_group_name  = \"$RESOURCE_GROUP\""
echo "    storage_account_name = \"$STORAGE_ACCOUNT\""
echo "    container_name       = \"$CONTAINER_NAME\""
echo "    key                  = \"infra-assessment.tfstate\""
echo "  }"
echo ""
echo "Then run: terraform init -migrate-state"
