resource "azurerm_user_assigned_identity" "this" {
  for_each = var.identities

  name                = "${var.name_prefix}-id-${each.value.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = local.tags
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = azurerm_user_assigned_identity.this[each.value.principal_key].principal_id
}