output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.this.name
}

output "app_subnet_id" {
  description = "ID of the application subnet"
  value       = azurerm_subnet.app.id
}

output "reserved_subnet_id" {
  description = "ID of the reserved subnet"
  value       = azurerm_subnet.reserved.id
}

output "nsg_id" {
  description = "ID of the NSG"
  value       = azurerm_network_security_group.app.id
}
