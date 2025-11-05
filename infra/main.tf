# Data source to get current Azure client config (includes tenant_id)
data "azurerm_client_config" "current" {}

locals {
  env_suffix          = var.environment
  resource_group_name = "mcda-${local.env_suffix}-rg"
  aks_name            = "mcda-${local.env_suffix}-aks"
  acr_name            = "mcda${local.env_suffix}acr" # ACR names must be globally unique, alphanumeric, lowercase
  key_vault_name      = "mcda-${local.env_suffix}-kv"
  cosmos_db_name      = "${var.cosmos_db_account_name}${local.env_suffix}" # Cosmos DB names must be globally unique, alphanumeric, lowercase, 44 chars max
  tenant_id           = var.tenant_id != "" ? var.tenant_id : data.azurerm_client_config.current.tenant_id
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = !var.key_vault_purge_protection_enabled
      recover_soft_deleted_key_vaults = true
    }
  }
}

resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_container_registry" "acr" {
  name                = local.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = var.acr_sku
  admin_enabled       = true

  dynamic "georeplications" {
    for_each = var.enable_acr_geo_replication ? var.acr_geo_replication_locations : []
    content {
      location = georeplications.value
    }
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = local.aks_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "mcda-${local.env_suffix}"

  default_node_pool {
    name                = "default"
    node_count          = var.enable_aks_auto_scaling ? null : var.aks_node_count
    vm_size             = var.aks_vm_size
    auto_scaling_enabled = var.enable_aks_auto_scaling

    dynamic "auto_scaling" {
      for_each = var.enable_aks_auto_scaling ? [1] : []
      content {
        min_count = var.aks_min_count
        max_count = var.aks_max_count
      }
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
  }

  role_based_access_control_enabled = var.enable_aks_rbac

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_key_vault" "kv" {
  name                = local.key_vault_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = local.tenant_id
  sku_name            = "standard"

  soft_delete_retention_days = var.key_vault_soft_delete_retention_days
  purge_protection_enabled   = var.key_vault_purge_protection_enabled

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_cosmosdb_account" "cosmosdb" {
  name                = local.cosmos_db_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = var.cosmos_db_offer_type
  kind                = var.cosmos_db_kind

  consistency_policy {
    consistency_level = var.cosmos_db_consistency_level
  }

  geo_location {
    location          = var.cosmos_db_geo_location_location
    failover_priority = var.cosmos_db_geo_location_failover_priority
  }

  dynamic "capabilities" {
    for_each = var.cosmos_db_capabilities
    content {
      name = capabilities.value
    }
  }

  automatic_failover_enabled = var.cosmos_db_enable_automatic_failover
  is_virtual_network_filter_enabled = var.cosmos_db_is_virtual_network_filter_enabled

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_cosmosdb_mongo_database" "cosmosdb_mongo" {
  name                = var.cosmos_db_database_name
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmosdb.name
}

resource "azurerm_key_vault_secret" "mongo_uri" {
  name         = "MongoUri"
  value        = azurerm_cosmosdb_account.cosmosdb.connection_strings[0]
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_cosmosdb_account.cosmosdb]
}
