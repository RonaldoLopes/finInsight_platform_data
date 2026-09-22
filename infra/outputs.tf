output "resource_group_name" {
  value = module.storage.resource_group_name
}

output "databricks_workspace_url" {
  value = module.databricks.workspace_url
}

output "unity_catalog_name" {
  value = "fininsight_${var.environment}"
}
