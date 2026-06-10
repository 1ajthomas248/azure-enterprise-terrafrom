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