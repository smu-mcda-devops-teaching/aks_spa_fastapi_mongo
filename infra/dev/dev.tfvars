environment = "dev"
location    = "Canada Central"
# tenant_id is optional - will be auto-detected from Azure provider/service connection if not specified
# tenant_id = "<tenant-id>" # Uncomment and set if you want to explicitly specify

# Dev-specific configurations
aks_node_count                          = 1
aks_vm_size                            = "Standard_DS2_v2"
acr_sku                                = "Basic"
enable_acr_geo_replication             = false
enable_aks_auto_scaling                = false
key_vault_soft_delete_retention_days   = 7
key_vault_purge_protection_enabled     = false
enable_aks_rbac                        = false

# Cosmos DB for MongoDB - Dev (Serverless)
cosmos_db_account_name                  = "cosmosdb"
cosmos_db_kind                          = "MongoDB"
cosmos_db_offer_type                    = "Standard"
cosmos_db_consistency_level             = "Session"
cosmos_db_geo_location_location         = "Canada Central"
cosmos_db_capabilities                  = ["EnableMongo", "EnableServerless","EnableAggregationPipeline"]
cosmos_db_serverless                    = true
cosmos_db_enable_automatic_failover     = false
cosmos_db_enable_multiple_write_locations = false
cosmos_db_database_name                 = "mcda-dev-db"
