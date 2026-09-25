output "id" {
  description = "Resource ID of the Key Vault"
  value       = azurerm_key_vault.this.id
}

output "name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.this.name
}

output "uri" {
  description = "URI of the Key Vault, used by applications to connect"
  value       = azurerm_key_vault.this.vault_uri
}

output "private_endpoint_id" {
  description = "Resource ID of the Key Vault private endpoint, if created"
  value       = var.private_endpoint != null ? azurerm_private_endpoint.this[0].id : null
}

output "private_endpoint_ip" {
  description = "Private IP address of the Key Vault private endpoint, if created"
  value = (
    var.private_endpoint != null
    ? azurerm_private_endpoint.this[0].private_service_connection[0].private_ip_address
    : null
  )
}

output "role_assignment_ids" {
  description = "Map of role assignment keys to role assignment IDs"
  value = {
    for key, assignment in azurerm_role_assignment.this :
    key => assignment.id
  }
}
