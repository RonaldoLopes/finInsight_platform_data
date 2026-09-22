resource "azurerm_databricks_workspace" "dbw" {
  name                = "dbw-fininsight-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "premium"
}
resource "azurerm_databricks_access_connector" "connector" {
  name                = "dbac-fininsight-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  identity { type = "SystemAssigned" }
}

resource "azurerm_role_assignment" "blob_contrib" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.connector.identity[0].principal_id
}

resource "azurerm_role_assignment" "queue_contrib" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Queue Data Contributor"
  principal_id         = azurerm_databricks_access_connector.connector.identity[0].principal_id
}

resource "azurerm_role_assignment" "eventgrid_contrib" {
  scope                = var.resource_group_id
  role_definition_name = "EventGrid EventSubscription Contributor"
  principal_id         = azurerm_databricks_access_connector.connector.identity[0].principal_id
}

resource "azurerm_role_assignment" "storage_acct_contrib" {
  scope                = var.resource_group_id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_databricks_access_connector.connector.identity[0].principal_id
}
