terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"

  # Backend configuration is provided via backend config files:
  # terraform init -backend-config=dev/backend.conf
  # terraform init -backend-config=stage/backend.conf
  # terraform init -backend-config=prod/backend.conf
  backend "azurerm" {
    # Values come from backend config files in environment folders
  }
}
