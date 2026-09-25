resource "azurerm_key_vault" "this" {
  name                = local.names.key_vault
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = var.tenant_id
  sku_name            = var.sku_name

  rbac_authorization_enabled  = var.enable_rbac_authorization
  soft_delete_retention_days  = var.soft_delete_retention_days
  purge_protection_enabled    = var.purge_protection_enabled

  network_acls {
    default_action             = var.network_acls.default_action
    bypass                     = var.network_acls.bypass
    ip_rules                   = var.network_acls.ip_rules
    virtual_network_subnet_ids = var.network_acls.virtual_network_subnet_ids
  }

  tags = local.tags
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  scope                = azurerm_key_vault.this.id
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}

resource "azurerm_private_endpoint" "this" {
  count = var.private_endpoint != null ? 1 : 0

  name                = local.names.private_endpoint
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.private_endpoint.subnet_id

  private_service_connection {
    name                           = "kv-connection"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_endpoint.create_dns_zone ? [1] : []

    content {
      name                 = "default"
      private_dns_zone_ids = [azurerm_private_dns_zone.this[0].id]
    }
  }

  tags = local.tags
}

resource "azurerm_private_dns_zone" "this" {
  count = var.private_endpoint != null && var.private_endpoint.create_dns_zone ? 1 : 0

  name                = local.private_dns_zone_name
  resource_group_name = local.dns_zone_resource_group

  tags = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  count = var.private_endpoint != null && var.private_endpoint.create_dns_zone ? 1 : 0

  name                  = local.names.dns_zone_link
  resource_group_name   = local.dns_zone_resource_group
  private_dns_zone_name = azurerm_private_dns_zone.this[0].name
  virtual_network_id    = var.private_endpoint.vnet_id
  registration_enabled  = false

  tags = local.tags
}
