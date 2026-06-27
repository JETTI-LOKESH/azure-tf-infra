variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "resource_group_id" {
  description = "ID of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "deployer_object_id" {
  description = "Object ID of the deployer (user or service principal)"
  type        = string
}

variable "extra_deployer_object_ids" {
  description = "Additional object IDs that need deployer-level Key Vault access"
  type        = list(string)
  default     = []
}

variable "vm_identity_principal_id" {
  description = "Principal ID of the VM's managed identity"
  type        = string
}

variable "ssh_private_key_pem" {
  description = "SSH private key to store in Key Vault"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
