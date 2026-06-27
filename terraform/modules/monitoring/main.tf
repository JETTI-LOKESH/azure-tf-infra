resource "azurerm_log_analytics_workspace" "this" {
  name                = "law-${var.project_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name                       = "diag-keyvault"
  target_resource_id         = var.keyvault_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_monitor_action_group" "this" {
  name                = "ag-${var.project_name}"
  resource_group_name = var.resource_group_name
  short_name          = "InfraAlert"

  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "vm_availability" {
  name                = "alert-vm-availability-${var.project_name}"
  resource_group_name = var.resource_group_name
  scopes              = [var.vm_id]
  description         = "Alert when VM availability drops below 100%"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "VmAvailabilityMetric"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }

  tags = var.tags
}

resource "azurerm_monitor_metric_alert" "keyvault_availability" {
  name                = "alert-kv-availability-${var.project_name}"
  resource_group_name = var.resource_group_name
  scopes              = [var.keyvault_id]
  description         = "Alert when Key Vault availability drops below 100%"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.KeyVault/vaults"
    metric_name      = "Availability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 100
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }

  tags = var.tags
}
