output "vnet_id" {
  description = "ID of the created virtual network"
  value       = azurerm_virtual_network.enterprise_vnet.id
}

output "vnet_name" {
  description = "Name of the created virtual network"
  value       = azurerm_virtual_network.enterprise_vnet.name
}

output "subnets" {
  description = "Map of the subnets in the virtual network"

  value = {
    for subnet_key, subnet in azurerm_subnet.this :
    subnet_key => {
      id               = subnet.id
      name             = subnet.name
      address_prefixes = subnet.address_prefixes
    }
  }
}

output "subnet_ids" {
  description = "Map of the subnet names to their respective IDs"

  value = {
    for subnet_name, subnet in azurerm_subnet.this :
    subnet_name => subnet.id
  }
}

output "nsg_ids" {
  description = "Map of the network security group names to their respective IDs"

  value = merge({
    for nsg_name, nsg in azurerm_network_security_group.app_nsg :
    nsg_name => nsg.id
    },
    {
      for nsg_name, nsg in azurerm_network_security_group.vm_nsg :
      nsg_name => nsg.id
    }
  )
}

output "app_subnet_id" {
  description = "ID of the App Service integration subnet."
  value       = azurerm_subnet.this["app"].id
}

output "vm_subnet_id" {
  description = "ID of the virtual machine subnet."
  value       = azurerm_subnet.this["vm"].id
}

output "private_endpoint_subnet_id" {
  description = "ID of the private endpoint subnet."
  value       = azurerm_subnet.this["private_endpoints"].id
}

output "application_gateway_subnet_id" {
  description = "ID of the Application Gateway subnet."
  value       = azurerm_subnet.this["appgw"].id
}

output "bastion_subnet_id" {
  description = "ID of the Azure Bastion subnet."
  value       = azurerm_subnet.this["bastion"].id
}

output "bastion_host_id" {
  description = "ID of the Azure Bastion host."
  value       = var.enable_bastion ? azurerm_bastion_host.this[0].id : null
}

output "bastion_host_name" {
  description = "Name of the bastion host"
  value       = var.enable_bastion ? azurerm_bastion_host.this[0].name : null
}

output "bastion_public_ip" {
  description = "Public IP for the Azure Bastion host"
  value       = var.enable_bastion ? azurerm_public_ip.bastion[0].ip_address : null
}

output "application_gateway_id" {
  description = "ID of the Application Gateway."
  value       = var.enable_application_gateway ? azurerm_application_gateway.this[0].id : null
}

output "application_gateway_name" {
  description = "Name of the Application Gateway."
  value       = var.enable_application_gateway ? azurerm_application_gateway.this[0].name : null
}

output "application_gateway_public_ip_address" {
  description = "Public IP address assigned to the Application Gateway."
  value       = var.enable_application_gateway ? azurerm_public_ip.application_gateway[0].ip_address : null
}