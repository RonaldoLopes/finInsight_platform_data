resource "databricks_storage_credential" "external" {
  name = "cred-fininsight-${var.environment}"
  azure_managed_identity {
    access_connector_id = var.access_connector_id
  }
}

resource "databricks_external_location" "bronze" {
  name            = "loc-bronze-${var.environment}"
  url             = "abfss://bronze@${var.storage_account_name}.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.external.name
}

resource "databricks_external_location" "catalog_root" {
  name            = "loc-catalog-root-${var.environment}"
  url             = "abfss://unitycatalog@${var.storage_account_name}.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.external.name
}

resource "databricks_catalog" "fininsight" {
  name         = "fininsight_${var.environment}"
  comment      = "Catalogo da plataforma FinInsight"
  storage_root = databricks_external_location.catalog_root.url

  depends_on = [databricks_external_location.catalog_root]
}

resource "databricks_schema" "bronze" {
  catalog_name = databricks_catalog.fininsight.name
  name         = "bronze"
}

resource "databricks_schema" "silver" {
  catalog_name = databricks_catalog.fininsight.name
  name         = "silver"
}

resource "databricks_schema" "gold" {
  catalog_name = databricks_catalog.fininsight.name
  name         = "gold"
}