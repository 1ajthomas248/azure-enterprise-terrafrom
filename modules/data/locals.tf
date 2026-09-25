locals {
  tags = merge(
    var.common_tags,
    {
      managed_by = "terraform"
    }
  )

  names = {
    sql_server           = "${var.name_prefix}-sql"
    sql_private_endpoint = "${var.name_prefix}-pe-sql"
    sql_dns_zone_link    = "${var.name_prefix}-dns-link-sql"
    storage_private_endpoint = "${var.name_prefix}-pe-sa"
    storage_dns_zone_link    = "${var.name_prefix}-dns-link-sa"
  }

  sql_private_dns_zone_name     = "privatelink.database.windows.net"
  storage_private_dns_zone_name = "privatelink.blob.core.windows.net"

  role_assignments_sql     = { for k, v in var.role_assignments : k => v if v.service == "sql" }
  role_assignments_storage = { for k, v in var.role_assignments : k => v if v.service == "storage" }
}
