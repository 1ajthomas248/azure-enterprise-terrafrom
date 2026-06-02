resource "azurerm_virtual_network" "enterprise-vnet" {
  name = "enterprise-vnet"
  resource_group_name = azurerm_resource_group.azure_enterprise_project.name
  location = azurerm_resource_group.azure_enterprise_project.location

  address_space = [var.address_space]

  subnet {
    name = "vm-subnet"
    address_prefixes = [var.address_prefix[0]]
  }

  subnet {
    name = "app-subnet"
    address_prefixes = [var.address_prefix[1]]
  }

  subnet {
    name = "priv-endpoint-subnet"
    address_prefixes = [var.address_prefix[2]]
  }

  subnet {
    name = "appgw-subnet"
    address_prefixes = [var.address_prefix[3]]
  }

  subnet {
    name = "AzureBastionSubnet"
    address_prefixes = [var.address_prefix[4]]
  }
}

resource "azurerm_network_security_group" "app_nsg" {
  name = "app_nsg"
  resource_group_name = azurerm_resource_group.azure_enterprise_project.name
  location = azurerm_resource_group.azure_enterprise_project.location

  security_rule {
    name = "allow-https-priv-endpoint-443"
    priority = 100
    direction = "Outbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "443"
    source_address_prefix = "*"
    destination_address_prefix = var.address_prefix[2]
  }

  security_rule {
    name = "allow-sql-priv-endpoint-1433"
    priority = 110
    direction = "Outbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "1433"
    source_address_prefix = "*"
    destination_address_prefix = var.address_prefix[2]
  }
}

resource "azurerm_network_security_group" "vm_nsg" {
  name = "vm_nsg" 
  resource_group_name = azurerm_resource_group.azure_enterprise_project.name
  location = azurerm_resource_group.azure_enterprise_project.location

  security_rule {
    name = "allow-https-priv-endpoint-443"
    priority = 200
    direction = "Outbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "443"
    source_address_prefix = "*"
    destination_address_prefix = var.address_prefix[2]
  }

  security_rule {
    name = "allow-sql-priv-endpoint-1433"
    priority = 210
    direction = "Outbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "1433"
    source_address_prefix = "*"
    destination_address_prefix = var.address_prefix[2]
  }

  security_rule {
    name = "allow-ssh"
    priority = 300
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = var.address_prefix[4]
    destination_address_prefix = var.address_prefix[4]
  }

  security_rule {
    name = "allow-rdp"
    priority = 310
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "3389"
    source_address_prefix = var.address_prefix[4]
    destination_address_prefix = var.address_prefix[0]
  }

  security_rule {
    name = "allow-80/443"
    priority = 320
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_ranges = ["80", "443"]
    source_address_prefix = var.address_prefix[3]
    destination_address_prefix = var.address_prefix[0]
  }
}