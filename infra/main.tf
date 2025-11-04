provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "aks-rg"
  location = "Canada Central"
}

resource "azurerm_container_registry" "acr" {
  name                = "myacrregistry"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  admin_enabled       = true
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "myakscluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "myaks"
  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
  }
  identity {
    type = "SystemAssigned"
  }
  network_profile {
    network_plugin = "azure"
  }
}

resource "azurerm_key_vault" "kv" {
  name                = "mykeyvaultaks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = "<tenant-id>"
  sku_name            = "standard"
}

resource "azurerm_key_vault_secret" "mongo_uri" {
  name         = "MongoUri"
  value        = "<your-mongo-connection-string>"
  key_vault_id = azurerm_key_vault.kv.id
}
