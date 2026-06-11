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
  name     = "azure-enterprise-project"
  location = "East US"
}

module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.azure_enterprise_project.name
  location            = azurerm_resource_group.azure_enterprise_project.location
  name_prefix         = "azure-enterprise"

  common_tags = {
    environment = "dev"
    project     = "azure-enterprise"
  }

  vnet = {
    name          = "enterprise-vnet"
    address_space = ["10.0.0.0/16"]
  }

  subnets = {
    app = {
      name             = "app-subnet"
      address_prefixes = ["10.0.1.0/24"]
      nsg_enabled      = true

      delegation = {
        name                    = "app-service-delegation"
        service_delegation_name = "Microsoft.Web/serverFarms"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/action"
        ]
      }
    }

    vm = {
      name             = "vm-subnet"
      address_prefixes = ["10.0.2.0/24"]
      nsg_enabled      = true
    }

    private_endpoints = {
      name             = "private-endpoints-subnet"
      address_prefixes = ["10.0.3.0/24"]
      nsg_enabled      = false
    }

    appgw = {
      name             = "appgw-subnet"
      address_prefixes = ["10.0.4.0/24"]
      nsg_enabled      = false
    }

    bastion = {
      name             = "AzureBastionSubnet"
      address_prefixes = ["10.0.5.0/24"]
      nsg_enabled      = false
    }
  }
}

module "identity" {
  source = "./modules/identity"

  resource_group_name = azurerm_resource_group.azure_enterprise_project.name
  location            = azurerm_resource_group.azure_enterprise_project.location
  name_prefix         = "azure-enterprise"

  common_tags = {
    environment = "dev"
    project     = "azure-enterprise"
  }

  identities = {
    app = {
      name_suffix = "app"
    }

    vm = {
      name_suffix = "vm"
    }
  }
}