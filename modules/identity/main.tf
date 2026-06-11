resource "azurerm_user_assigned_identity" "this" {
  for_each = var.identities

  name                = "${var.name_prefix}-id-${each.value.name_suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = local.tags
}