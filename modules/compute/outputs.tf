output "vm_ids" {
  description = "Map of VM keys to VM resource IDs"
  value = {
    for key, vm in azurerm_linux_virtual_machine.vm : key => vm.id
  }
}

output "vm_private_ips" {
  description = "Map of VM keys to their private IP addresses"
  value = {
    for key, nic in azurerm_network_interface.vm : key => nic.private_ip_address
  }
}

output "vm_nic_ids" {
  description = "Map of VM keys to NIC resource IDs"
  value = {
    for key, nic in azurerm_network_interface.vm : key => nic.id
  }
}

output "service_plan_id" {
  description = "Resource ID of the App Service Plan, if created"
  value       = var.app_service != null ? azurerm_service_plan.this[0].id : null
}

output "app_service_id" {
  description = "Resource ID of the App Service, if created"
  value       = var.app_service != null ? azurerm_linux_web_app.this[0].id : null
}

output "app_service_name" {
  description = "Name of the App Service, if created"
  value       = var.app_service != null ? azurerm_linux_web_app.this[0].name : null
}

output "app_service_default_hostname" {
  description = "Default hostname of the App Service, if created"
  value       = var.app_service != null ? azurerm_linux_web_app.this[0].default_hostname : null
}
