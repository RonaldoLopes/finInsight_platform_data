variable "environment" {
  description = "Ambiente: dev, hml ou prod"
  type        = string
  validation {
    condition     = contains(["dev", "hml", "prod"], var.environment)
    error_message = "Environment deve ser: dev, hml ou prod"
  }
}

variable "location" {
  description = "Regiao Azure"
  type        = string
  default     = "eastus2"
  validation {
    condition     = contains(["eastus", "eastus2", "westus2"], var.location)
    error_message = "Location deve ser: eastus, eastus2 ou westus2"
  }
}
variable "metastore_id" {
  description = "ID do metastore Unity Catalog ja existente na conta/regiao"
  type        = string
}