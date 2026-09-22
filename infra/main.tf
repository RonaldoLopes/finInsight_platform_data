module "storage" {
  source      = "./modules/storage"
  environment = var.environment
  location    = var.location
}

module "keyvault" {
  source              = "./modules/keyvault"
  environment         = var.environment
  location            = var.location
  resource_group_name = module.storage.resource_group_name
}

module "databricks" {
  source              = "./modules/databricks"
  environment         = var.environment
  location            = var.location
  resource_group_name = module.storage.resource_group_name
  resource_group_id   = module.storage.resource_group_id
  storage_account_id  = module.storage.storage_account_id
}

module "unity_catalog" {
  source                  = "./modules/unity-catalog"
  environment             = var.environment
  location                = var.location
  storage_account_name    = module.storage.storage_account_name
  access_connector_id     = module.databricks.access_connector_id
  databricks_workspace_id = module.databricks.workspace_id
  metastore_id            = var.metastore_id

  depends_on = [module.storage, module.databricks]
}

module "ai_services" {
  source              = "./modules/ai-services"
  environment         = var.environment
  location            = var.location
  resource_group_name = module.storage.resource_group_name
}
