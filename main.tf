terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.2"
    }
  }
  required_version = ">= 1.14"
}

resource "azurerm_resource_group" "azure_enterprise_project" {
  name = "azure_enterprise_project"
  location = "East US"
}