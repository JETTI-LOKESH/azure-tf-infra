output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.this.id
}

output "action_group_id" {
  description = "ID of the action group"
  value       = azurerm_monitor_action_group.this.id
}
