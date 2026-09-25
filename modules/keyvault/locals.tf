locals {
  tags = merge(
    var.common_tags,
    {
      managed_by = "terraform"
    }
  )

  names = {
    key_vault        = "${var.name_prefix}-kv"
    private_endpoint = "${var.name_prefix}-pe-kv"
    dns_zone_link    = "${var.name_prefix}-dns-link-kv"
  }

  private_dns_zone_name = "privatelink.vaultcore.azure.net"

  dns_zone_resource_group = (
    var.private_endpoint != null && var.private_endpoint.dns_zone_resource_group != null
    ? var.private_endpoint.dns_zone_resource_group
    : var.resource_group_name
  )
}
