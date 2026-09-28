locals {
  common_tags = {
    environment = var.environment
    project     = var.name_prefix
  }
}

resource "azurerm_resource_group" "azure_enterprise_project" {
  name     = "${var.name_prefix}-project"
  location = var.location
}

module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.azure_enterprise_project.name
  location            = azurerm_resource_group.azure_enterprise_project.location
  name_prefix         = var.name_prefix
  common_tags         = local.common_tags

  enable_bastion             = var.enable_bastion
  enable_application_gateway = var.enable_application_gateway
  appgw_identity_id          = var.enable_application_gateway ? module.identity.identity_ids["appgw"] : null
  ssl_certificate_secret_id  = var.ssl_certificate_secret_id

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
  name_prefix         = var.name_prefix
  common_tags         = local.common_tags

  identities = {
    app   = { name_suffix = "app" }
    vm    = { name_suffix = "vm" }
    appgw = { name_suffix = "appgw" }
  }

  role_assignments = {}
}

data "azurerm_client_config" "current" {}

module "keyvault" {
  source = "./modules/keyvault"

  resource_group_name      = azurerm_resource_group.azure_enterprise_project.name
  location                 = azurerm_resource_group.azure_enterprise_project.location
  name_prefix              = var.name_prefix
  tenant_id                = data.azurerm_client_config.current.tenant_id
  common_tags              = local.common_tags
  purge_protection_enabled = var.purge_protection_enabled

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

    appgw_secrets_user = {
      principal_id         = module.identity.principal_ids["appgw"]
      role_definition_name = "Key Vault Secrets User"
    }
  }
}

module "data" {
  source = "./modules/data"

  resource_group_name        = azurerm_resource_group.azure_enterprise_project.name
  location                   = azurerm_resource_group.azure_enterprise_project.location
  name_prefix                = var.name_prefix
  private_endpoint_subnet_id = module.networking.private_endpoint_subnet_id
  vnet_id                    = module.networking.vnet_id
  common_tags                = local.common_tags

  sql = {
    administrator_login = "sqladmin"
  }

  sql_administrator_login_password = var.sql_administrator_login_password

  databases = {
    app = {
      sku_name    = var.sql_database_sku
      max_size_gb = 2
    }
  }

  storage = {
    account_tier             = "Standard"
    account_replication_type = var.storage_replication_type

    containers = {
      uploads = {}
    }
  }

  role_assignments = {
    app_sql_contributor = {
      principal_id         = module.identity.principal_ids["app"]
      role_definition_name = "Contributor"
      service              = "sql"
    }

    app_storage_blob_contributor = {
      principal_id         = module.identity.principal_ids["app"]
      role_definition_name = "Storage Blob Data Contributor"
      service              = "storage"
    }
  }
}

module "governance" {
  source = "./modules/governance"

  resource_group_name  = azurerm_resource_group.azure_enterprise_project.name
  resource_group_id    = azurerm_resource_group.azure_enterprise_project.id
  location             = azurerm_resource_group.azure_enterprise_project.location
  name_prefix          = var.name_prefix
  enable_resource_lock = var.enable_resource_lock
  common_tags          = local.common_tags

  allowed_locations = [lower(replace(var.location, " ", ""))]
  required_tags     = ["environment", "project"]

  budget = {
    monthly_amount   = 100
    start_date       = "2026-10-01T00:00:00Z"
    alert_thresholds = [80, 100]
    contact_emails   = var.budget_contact_emails
  }
}

module "compute" {
  source = "./modules/compute"

  resource_group_name = azurerm_resource_group.azure_enterprise_project.name
  location            = azurerm_resource_group.azure_enterprise_project.location
  name_prefix         = var.name_prefix
  common_tags         = local.common_tags

  vm_subnet_id = module.networking.vm_subnet_id

  vms = {
    api = {
      size           = "Standard_B2s"
      admin_username = "azureadmin"
      admin_ssh_key  = var.vm_admin_ssh_key
      identity_id    = module.identity.identity_ids["vm"]
    }
  }

  app_service = {
    plan_sku_name = var.plan_sku_name
    subnet_id     = module.networking.app_subnet_id
    identity_id   = module.identity.identity_ids["app"]
    key_vault_uri = module.keyvault.uri

    app_settings = {
      APPLICATIONINSIGHTS_CONNECTION_STRING = module.monitoring.app_insights_connection_string
    }

    app_stack = {
      python_version = "3.11"
    }
  }
}

module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name = azurerm_resource_group.azure_enterprise_project.name
  location            = azurerm_resource_group.azure_enterprise_project.location
  name_prefix         = var.name_prefix
  common_tags         = local.common_tags

  alert_email_receivers = [for email in var.budget_contact_emails : {
    name          = email
    email_address = email
  }]

  key_vault_id           = module.keyvault.id
  sql_server_id          = module.data.sql_server_id
  database_ids           = module.data.database_ids
  storage_account_id     = module.data.storage_account_id
  application_gateway_id = module.networking.application_gateway_id
  app_service_id         = module.compute.app_service_id
  vm_ids                 = module.compute.vm_ids
}
