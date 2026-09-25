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

  role_assignments = {}
}

data "azurerm_client_config" "current" {}

module "keyvault" {
  source = "./modules/keyvault"

  resource_group_name = azurerm_resource_group.azure_enterprise_project.name
  location            = azurerm_resource_group.azure_enterprise_project.location
  name_prefix         = "azure-enterprise"
  tenant_id           = data.azurerm_client_config.current.tenant_id

  common_tags = {
    environment = "dev"
    project     = "azure-enterprise"
  }

  purge_protection_enabled = false

  private_endpoint = {
    subnet_id = module.networking.private_endpoint_subnet_id
    vnet_id   = module.networking.vnet_id
  }

  role_assignments = {
    app_secrets_user = {
      principal_id         = module.identity.principal_ids["app"]
      role_definition_name = "Key Vault Secrets User"
    }

    vm_secrets_user = {
      principal_id         = module.identity.principal_ids["vm"]
      role_definition_name = "Key Vault Secrets User"
    }
  }
}

module "compute" {
  source = "./modules/compute"

  resource_group_name = azurerm_resource_group.azure_enterprise_project.name
  location            = azurerm_resource_group.azure_enterprise_project.location
  name_prefix         = "azure-enterprise"

  common_tags = {
    environment = "dev"
    project     = "azure-enterprise"
  }

  vm_subnet_id = module.networking.vm_subnet_id

  vms = {
    api = {
      size           = "Standard_B2s"
      admin_username = "azureadmin"
      admin_ssh_key  = "ssh-rsa REPLACE_WITH_YOUR_PUBLIC_KEY"
      identity_id    = module.identity.identity_ids["vm"]
    }
  }

  app_service = {
    subnet_id     = module.networking.app_subnet_id
    identity_id   = module.identity.identity_ids["app"]
    key_vault_uri = module.keyvault.uri

    app_stack = {
      python_version = "3.11"
    }
  }
}