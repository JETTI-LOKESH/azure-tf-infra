resource "azurerm_key_vault" "this" {
  name                       = "kv-${replace(var.project_name, "-", "")}${substr(md5(var.resource_group_id), 0, 6)}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  enable_rbac_authorization  = false

  # Deployer: full secret management
  access_policy {
    tenant_id = var.tenant_id
    object_id = var.deployer_object_id

    secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
    key_permissions    = ["Get", "List", "Create"]
  }

  # VM managed identity: read-only (least-privilege)
  access_policy {
    tenant_id = var.tenant_id
    object_id = var.vm_identity_principal_id

    secret_permissions = ["Get", "List"]
    key_permissions    = []
  }

  tags = var.tags
}

# TLS cert password placeholder — demonstrates secret lifecycle management
# In production, this would store the actual cert passphrase used by the service
resource "azurerm_key_vault_secret" "tls_cert_password" {
  name            = "tls-cert-password"
  value           = "auto-generated-${substr(md5(timestamp()), 0, 16)}"
  key_vault_id    = azurerm_key_vault.this.id
  expiration_date = timeadd(timestamp(), "2160h") # 90 days

  lifecycle {
    ignore_changes = [value, expiration_date]
  }

  tags = var.tags
}

resource "azurerm_key_vault_secret" "ssh_private_key" {
  name         = "vm-ssh-private-key"
  value        = var.ssh_private_key_pem
  key_vault_id = azurerm_key_vault.this.id

  tags = var.tags
}
