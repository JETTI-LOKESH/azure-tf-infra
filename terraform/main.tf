data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    environment = var.environment
    project     = var.project_name
    managed_by  = "terraform"
  }
}

# --- Networking Module ---
module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project_name        = var.project_name
  allowed_ssh_cidr    = var.allowed_ssh_cidr
  tags                = azurerm_resource_group.main.tags
}

# --- Compute Module ---
module "compute" {
  source = "./modules/compute"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project_name        = var.project_name
  vm_size             = var.vm_size
  admin_username      = var.admin_username
  subnet_id           = module.networking.app_subnet_id
  startup_script_path = "${path.module}/../scripts/startup.sh"
  tags                = azurerm_resource_group.main.tags
}

# --- Key Vault Module ---
module "keyvault" {
  source = "./modules/keyvault"

  resource_group_name      = azurerm_resource_group.main.name
  resource_group_id        = azurerm_resource_group.main.id
  location                 = azurerm_resource_group.main.location
  project_name             = var.project_name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  deployer_object_id       = data.azurerm_client_config.current.object_id
  vm_identity_principal_id = module.compute.vm_identity_principal_id
  ssh_private_key_pem      = module.compute.ssh_private_key_pem
  tags                     = azurerm_resource_group.main.tags
}

# --- Monitoring Module ---
module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  project_name        = var.project_name
  vm_id               = module.compute.vm_id
  keyvault_id         = module.keyvault.keyvault_id
  tags                = azurerm_resource_group.main.tags
}
