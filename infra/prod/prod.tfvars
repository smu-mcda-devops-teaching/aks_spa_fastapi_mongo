environment = "prod"
location    = "Canada Central"
# tenant_id is optional - will be auto-detected from Azure provider/service connection if not specified
# tenant_id = "<tenant-id>" # Uncomment and set if you want to explicitly specify

# Prod-specific configurations
aks_node_count                          = 3
aks_vm_size                            = "Standard_DS2_v2"
acr_sku                                = "Premium"
enable_acr_geo_replication             = true
acr_geo_replication_locations          = ["East US"]
enable_aks_auto_scaling                = true
aks_min_count                          = 3
aks_max_count                          = 10
key_vault_soft_delete_retention_days   = 90
key_vault_purge_protection_enabled     = true
enable_aks_rbac                        = true

# Cosmos DB for MongoDB - Prod (Serverless)
cosmos_db_account_name                  = "cosmosdb"
cosmos_db_kind                          = "MongoDB"
cosmos_db_offer_type                    = "Standard"
cosmos_db_consistency_level             = "BoundedStaleness" # Stronger consistency for prod
cosmos_db_geo_location_location         = "Canada Central"
cosmos_db_capabilities                  = ["EnableMongo", "EnableServerless", "EnableAggregationPipeline"]
cosmos_db_serverless                    = true
cosmos_db_enable_automatic_failover     = true
cosmos_db_enable_multiple_write_locations = true # Enable for high availability
cosmos_db_database_name                 = "mcda-prod-db"
