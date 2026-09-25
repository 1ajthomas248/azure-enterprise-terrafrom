# ── SQL Server ────────────────────────────────────────────────────────────────

resource "azurerm_mssql_server" "this" {
  count = var.sql != null ? 1 : 0

  name                          = local.names.sql_server
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = var.sql.version
  administrator_login           = var.sql.administrator_login
  administrator_login_password  = var.sql_administrator_login_password
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false

  dynamic "azuread_administrator" {
    for_each = var.sql.azure_ad_admin != null ? [var.sql.azure_ad_admin] : []

    content {
      login_username = azuread_administrator.value.login_username
      object_id      = azuread_administrator.value.object_id
      tenant_id      = azuread_administrator.value.tenant_id
    }
  }

  tags = local.tags
}

resource "azurerm_mssql_database" "this" {
  for_each = var.sql != null ? var.databases : {}

  name         = "${var.name_prefix}-db-${each.key}"
  server_id    = azurerm_mssql_server.this[0].id
  sku_name     = each.value.sku_name
  max_size_gb  = each.value.max_size_gb

  tags = local.tags
}

resource "azurerm_private_endpoint" "sql" {
  count = var.sql != null ? 1 : 0

  name                = local.names.sql_private_endpoint
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "sql-connection"
    private_connection_resource_id = azurerm_mssql_server.this[0].id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql[0].id]
  }

  tags = local.tags
}

resource "azurerm_private_dns_zone" "sql" {
  count = var.sql != null ? 1 : 0

  name                = local.sql_private_dns_zone_name
  resource_group_name = var.resource_group_name

  tags = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  count = var.sql != null ? 1 : 0

  name                  = local.names.sql_dns_zone_link
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.sql[0].name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false

  tags = local.tags
}

resource "azurerm_role_assignment" "sql" {
  for_each = var.sql != null ? local.role_assignments_sql : {}

  scope                = azurerm_mssql_server.this[0].id
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}

# ── Storage Account ───────────────────────────────────────────────────────────

resource "random_string" "storage_suffix" {
  count   = var.storage != null ? 1 : 0
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "this" {
  count = var.storage != null ? 1 : 0

  name                = lower(replace("${var.name_prefix}sa${random_string.storage_suffix[0].result}", "-", ""))
  resource_group_name = var.resource_group_name
  location            = var.location

  account_tier             = var.storage.account_tier
  account_replication_type = var.storage.account_replication_type
  account_kind             = "StorageV2"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true

  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  tags = local.tags
}

resource "azurerm_storage_container" "this" {
  for_each = var.storage != null ? var.storage.containers : {}

  name                  = each.key
  storage_account_id    = azurerm_storage_account.this[0].id
  container_access_type = each.value.access_type
}

resource "azurerm_private_endpoint" "storage" {
  count = var.storage != null ? 1 : 0

  name                = local.names.storage_private_endpoint
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "storage-blob-connection"
    private_connection_resource_id = azurerm_storage_account.this[0].id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage[0].id]
  }

  tags = local.tags
}

resource "azurerm_private_dns_zone" "storage" {
  count = var.storage != null ? 1 : 0

  name                = local.storage_private_dns_zone_name
  resource_group_name = var.resource_group_name

  tags = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  count = var.storage != null ? 1 : 0

  name                  = local.names.storage_dns_zone_link
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage[0].name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false

  tags = local.tags
}

resource "azurerm_role_assignment" "storage" {
  for_each = var.storage != null ? local.role_assignments_storage : {}

  scope                = azurerm_storage_account.this[0].id
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}
