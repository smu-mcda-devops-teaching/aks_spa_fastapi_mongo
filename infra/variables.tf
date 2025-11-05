variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be one of: dev, stage, prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "Canada Central"
}

variable "tenant_id" {
  description = "Azure AD tenant ID (optional - will be auto-detected from Azure provider if not provided)"
  type        = string
  default     = ""
}

variable "aks_node_count" {
  description = "Number of nodes in AKS cluster"
  type        = number
  default     = 1
}

variable "aks_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Basic"
}

variable "enable_acr_geo_replication" {
  description = "Enable geo-replication for ACR (Premium SKU only)"
  type        = bool
  default     = false
}

variable "acr_geo_replication_locations" {
  description = "List of locations for ACR geo-replication"
  type        = list(string)
  default     = []
}

variable "enable_aks_auto_scaling" {
  description = "Enable auto-scaling for AKS cluster"
  type        = bool
  default     = false
}

variable "aks_min_count" {
  description = "Minimum node count for AKS (when auto-scaling enabled)"
  type        = number
  default     = 1
}

variable "aks_max_count" {
  description = "Maximum node count for AKS (when auto-scaling enabled)"
  type        = number
  default     = 10
}

variable "key_vault_soft_delete_retention_days" {
  description = "Soft delete retention days for Key Vault"
  type        = number
  default     = 7
}

variable "key_vault_purge_protection_enabled" {
  description = "Enable purge protection for Key Vault"
  type        = bool
  default     = false
}

variable "enable_aks_rbac" {
  description = "Enable RBAC on AKS cluster"
  type        = bool
  default     = false
}

variable "cosmos_db_account_name" {
  description = "Name of the Cosmos DB account (will be prefixed with environment)"
  type        = string
  default     = "cosmosdb"
}

variable "cosmos_db_kind" {
  description = "Kind of Cosmos DB account"
  type        = string
  default     = "MongoDB"
}

variable "cosmos_db_offer_type" {
  description = "Offer type for Cosmos DB account"
  type        = string
  default     = "Standard"
}

variable "cosmos_db_consistency_level" {
  description = "Consistency level for Cosmos DB"
  type        = string
  default     = "Session"
}

variable "cosmos_db_geo_location_location" {
  description = "Primary location for Cosmos DB"
  type        = string
  default     = "Canada Central"
}

variable "cosmos_db_geo_location_failover_priority" {
  description = "Failover priority for primary geo location"
  type        = number
  default     = 0
}

variable "cosmos_db_capabilities" {
  description = "Capabilities for Cosmos DB (EnableMongo, EnableServerless)"
  type        = list(string)
  default     = ["EnableMongo", "EnableServerless"]
}

variable "cosmos_db_serverless" {
  description = "Enable serverless mode for Cosmos DB (cost-effective for variable workloads)"
  type        = bool
  default     = true
}

variable "cosmos_db_enable_automatic_failover" {
  description = "Enable automatic failover for Cosmos DB"
  type        = bool
  default     = false
}

variable "cosmos_db_enable_multiple_write_locations" {
  description = "Enable multiple write locations for Cosmos DB"
  type        = bool
  default     = false
}

variable "cosmos_db_is_virtual_network_filter_enabled" {
  description = "Enable virtual network filtering for Cosmos DB"
  type        = bool
  default     = false
}

variable "cosmos_db_database_name" {
  description = "Name of the Cosmos DB database"
  type        = string
  default     = "mcdadb"
}

# Grafana Azure AD Configuration
variable "grafana_azure_ad_client_id" {
  description = "Azure AD Application (client) ID for Grafana authentication"
  type        = string
  default     = ""
  sensitive   = true
}

variable "grafana_azure_ad_client_secret" {
  description = "Azure AD Application client secret for Grafana authentication"
  type        = string
  default     = ""
  sensitive   = true
}

# ==============================================================================
# Grafana Cloud Monitoring Configuration (Optional)
# ==============================================================================
# These variables configure Grafana Cloud integration for k8s-monitoring
# 
# IMPORTANT: Do NOT commit these values to Git!
# Set them via environment variables or a separate secrets.tfvars file
#
# To enable Grafana Cloud monitoring:
# 1. Sign up at grafana.com/products/cloud
# 2. Create a stack and get your credentials
# 3. Set these variables:
#
#    Option 1: Environment variables (recommended)
#      export TF_VAR_destinations_prometheus_url="https://..."
#      export TF_VAR_destinations_prometheus_username="..."
#      export TF_VAR_destinations_prometheus_password="..."
#      # ... etc
#
#    Option 2: Separate secrets file
#      Create infra/dev/grafana-cloud-secrets.tfvars with your values
#      Then: terraform apply -var-file="dev/dev.tfvars" -var-file="dev/grafana-cloud-secrets.tfvars"
#
# ==============================================================================

variable "destinations_prometheus_url" {
  description = "Grafana Cloud Prometheus endpoint URL"
  type        = string
  default     = ""
  sensitive   = true
}

variable "destinations_prometheus_username" {
  description = "Grafana Cloud Prometheus username (instance ID)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "destinations_prometheus_password" {
  description = "Grafana Cloud API key for Prometheus"
  type        = string
  default     = ""
  sensitive   = true
}

variable "destinations_loki_url" {
  description = "Grafana Cloud Loki endpoint URL"
  type        = string
  default     = ""
  sensitive   = true
}

variable "destinations_loki_username" {
  description = "Grafana Cloud Loki username (user ID)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "destinations_loki_password" {
  description = "Grafana Cloud API key for Loki"
  type        = string
  default     = ""
  sensitive   = true
}

variable "destinations_otlp_url" {
  description = "Grafana Cloud OTLP endpoint URL"
  type        = string
  default     = ""
  sensitive   = true
}

variable "destinations_otlp_username" {
  description = "Grafana Cloud OTLP username (instance ID)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "destinations_otlp_password" {
  description = "Grafana Cloud API key for OTLP"
  type        = string
  default     = ""
  sensitive   = true
}

variable "fleetmanagement_url" {
  description = "Grafana Cloud Fleet Management URL"
  type        = string
  default     = ""
  sensitive   = true
}

variable "fleetmanagement_username" {
  description = "Grafana Cloud Fleet Management username (instance ID)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "fleetmanagement_password" {
  description = "Grafana Cloud API key for Fleet Management"
  type        = string
  default     = ""
  sensitive   = true
}