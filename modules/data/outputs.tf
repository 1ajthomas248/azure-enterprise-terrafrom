output "sql_server_id" {
  description = "Resource ID of the SQL Server, if created"
  value       = var.sql != null ? azurerm_mssql_server.this[0].id : null
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL Server, if created"
  value       = var.sql != null ? azurerm_mssql_server.this[0].fully_qualified_domain_name : null
}

output "database_ids" {
  description = "Map of database keys to resource IDs"
  value = {
    for key, db in azurerm_mssql_database.this : key => db.id
  }
}

output "sql_private_endpoint_id" {
  description = "Resource ID of the SQL private endpoint, if created"
  value       = var.sql != null ? azurerm_private_endpoint.sql[0].id : null
}

output "storage_account_id" {
  description = "Resource ID of the Storage Account, if created"
  value       = var.storage != null ? azurerm_storage_account.this[0].id : null
}

output "storage_account_name" {
  description = "Name of the Storage Account, if created"
  value       = var.storage != null ? azurerm_storage_account.this[0].name : null
}

output "storage_primary_blob_endpoint" {
  description = "Primary blob service endpoint of the Storage Account, if created"
  value       = var.storage != null ? azurerm_storage_account.this[0].primary_blob_endpoint : null
}

output "storage_private_endpoint_id" {
  description = "Resource ID of the storage blob private endpoint, if created"
  value       = var.storage != null ? azurerm_private_endpoint.storage[0].id : null
}
