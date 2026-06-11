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

output "role_assignment_ids" {
  description = "Map of role assignment keys to role assignment IDs."
  value = {
    for key, assignment in azurerm_role_assignment.this :
    key => assignment.id
  }
}