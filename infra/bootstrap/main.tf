terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "Canada Central"
}

variable "resource_group_name" {
  description = "Name of the resource group for Terraform state storage"
  type        = string
  default     = "terraform-state-rg"
}

variable "storage_account_name" {
  description = "Name of the storage account (must be globally unique, lowercase, alphanumeric, 3-24 chars)"
  type        = string
  default     = "tfstatemcda2025" # Change this to something unique
}

variable "container_name" {
  description = "Name of the container for Terraform state"
  type        = string
  default     = "tfstate"
}

# Resource group for Terraform state storage
resource "azurerm_resource_group" "terraform_state" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Purpose = "Terraform State Storage"
    ManagedBy = "Terraform"
  }
}

# Storage account for Terraform state
resource "azurerm_storage_account" "terraform_state" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.terraform_state.name
  location                 = azurerm_resource_group.terraform_state.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  # Enable blob versioning for state file recovery
  blob_properties {
    versioning_enabled = true
  }

  tags = {
    Purpose = "Terraform State Storage"
    ManagedBy = "Terraform"
  }
}

# Container for Terraform state files
resource "azurerm_storage_container" "terraform_state" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.terraform_state.name
  container_access_type = "private"
}

output "resource_group_name" {
  description = "Name of the resource group created for Terraform state"
  value       = azurerm_resource_group.terraform_state.name
}

output "storage_account_name" {
  description = "Name of the storage account created for Terraform state"
  value       = azurerm_storage_account.terraform_state.name
}

output "container_name" {
  description = "Name of the container created for Terraform state"
  value       = azurerm_storage_container.terraform_state.name
}

output "backend_config_note" {
  description = "Note about backend configuration"
  value       = "After running this bootstrap, update provider.tf in dev/stage/prod folders with the storage_account_name above. Each environment uses a different key: dev/terraform.tfstate, stage/terraform.tfstate, prod/terraform.tfstate"
}
