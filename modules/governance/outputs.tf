output "policy_assignment_ids" {
  description = "Map of policy assignment keys to resource IDs"
  value = merge(
    {
      allowed_locations   = azurerm_resource_group_policy_assignment.allowed_locations.id
      storage_https       = azurerm_resource_group_policy_assignment.storage_https.id
      kv_purge_protection = azurerm_resource_group_policy_assignment.kv_purge_protection.id
      sql_auditing        = azurerm_resource_group_policy_assignment.sql_auditing.id
    },
    {
      for tag, assignment in azurerm_resource_group_policy_assignment.require_tag :
      "require_tag_${tag}" => assignment.id
    }
  )
}

output "resource_lock_id" {
  description = "Resource ID of the management lock on the resource group, if created"
  value       = var.enable_resource_lock ? azurerm_management_lock.resource_group[0].id : null
}

output "budget_id" {
  description = "Resource ID of the consumption budget, if created"
  value       = var.budget != null ? azurerm_consumption_budget_resource_group.this[0].id : null
}
