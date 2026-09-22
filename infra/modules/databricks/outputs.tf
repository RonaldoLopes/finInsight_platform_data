output "workspace_id" {
  value = azurerm_databricks_workspace.dbw.workspace_id
}

output "workspace_url" {
  value = "https://${azurerm_databricks_workspace.dbw.workspace_url}"
}

output "access_connector_id" {
  value = azurerm_databricks_access_connector.connector.id
}

output "workspace_resource_id" {
  value = azurerm_databricks_workspace.dbw.id
}