output "vm_id" {
  description = "ID of the virtual machine"
  value       = azurerm_linux_virtual_machine.this.id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_linux_virtual_machine.this.name
}

output "vm_identity_principal_id" {
  description = "Principal ID of the VM's managed identity"
  value       = azurerm_linux_virtual_machine.this.identity[0].principal_id
}

output "public_ip_address" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.this.ip_address
}

output "ssh_private_key_pem" {
  description = "SSH private key in PEM format"
  value       = tls_private_key.ssh.private_key_pem
  sensitive   = true
}
