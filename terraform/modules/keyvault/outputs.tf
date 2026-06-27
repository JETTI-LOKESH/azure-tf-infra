output "keyvault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.this.id
}

output "keyvault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.this.name
}

output "keyvault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.this.vault_uri
}
