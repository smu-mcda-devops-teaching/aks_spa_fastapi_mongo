output "environment" {
  description = "The environment name"
  value       = var.environment
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "kube_config" {
  description = "Kubernetes configuration file"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "acr_login_server" {
  description = "ACR login server URL"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_name" {
  description = "ACR name"
  value       = azurerm_container_registry.acr.name
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.kv.name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.kv.vault_uri
}

output "cosmos_db_account_name" {
  description = "Cosmos DB account name"
  value       = azurerm_cosmosdb_account.cosmosdb.name
}

output "cosmos_db_connection_strings" {
  description = "Cosmos DB connection strings"
  value       = azurerm_cosmosdb_account.cosmosdb.connection_strings
  sensitive   = true
}

output "cosmos_db_mongo_database_name" {
  description = "Cosmos DB MongoDB database name"
  value       = azurerm_cosmosdb_mongo_database.cosmosdb_mongo.name
}
