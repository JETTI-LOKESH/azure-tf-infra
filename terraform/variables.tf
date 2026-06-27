variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-infra-assessment"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "Sweden Central"
}

variable "vm_size" {
  description = "Size of the Linux VM"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the VM"
  type        = string
  default     = "0.0.0.0/0"
}

variable "environment" {
  description = "Environment tag (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "infra-assessment"
}
