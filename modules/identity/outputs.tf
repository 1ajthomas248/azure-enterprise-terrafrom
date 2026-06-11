output "identity_ids" {
  description = "Map of identity keys to user-assigned managed identities"
  value = {
    for key, identity in azurerm_user_assigned_identity.this : key => identity.id
  }
}

output "client_ids" {
  description = "Map of identity keys to client IDs"
  value = {
    for key, identity in azurerm_user_assigned_identity.this : key => identity.client_id
  }
}

output "principal_ids" {
  description = "Map of identity keys to principal IDs"
  value = {
    for key, identity in azurerm_user_assigned_identity.this : key => identity.principal_id
  }
}