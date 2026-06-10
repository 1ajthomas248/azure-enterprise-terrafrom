resource "azurerm_virtual_network" "enterprise_vnet" {
  name                = var.vnet.name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.vnet.address_space

  tags = local.tags
}

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.enterprise_vnet.name
  address_prefixes     = each.value.address_prefixes
}

resource "azurerm_network_security_group" "app_nsg" {
  for_each = var.subnets["app"].nsg_enabled ? { app = var.subnets["app"] } : {}

  name                = "app_nsg"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = local.tags

  security_rule {
    name                       = "allow-https-priv-endpoint-443"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = var.subnets["private_endpoints"].address_prefixes[0]
  }

  security_rule {
    name                       = "allow-sql-priv-endpoint-1433"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "*"
    destination_address_prefix = var.subnets["private_endpoints"].address_prefixes[0]
  }
}

resource "azurerm_network_security_group" "vm_nsg" {
  for_each = var.subnets["vm"].nsg_enabled ? { vm = var.subnets["vm"] } : {}

  name                = "vm_nsg"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = local.tags

  security_rule {
    name                       = "allow-https-priv-endpoint-443"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = var.subnets["private_endpoints"].address_prefixes[0]
  }

  security_rule {
    name                       = "allow-sql-priv-endpoint-1433"
    priority                   = 210
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "*"
    destination_address_prefix = var.subnets["private_endpoints"].address_prefixes[0]
  }

  security_rule {
    name                       = "allow-ssh"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.subnets["bastion"].address_prefixes[0]
    destination_address_prefix = var.subnets["vm"].address_prefixes[0]
  }

  security_rule {
    name                       = "allow-rdp"
    priority                   = 310
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.subnets["bastion"].address_prefixes[0]
    destination_address_prefix = var.subnets["vm"].address_prefixes[0]
  }

  security_rule {
    name                       = "allow-http-from-appgw-80"
    priority                   = 320
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = var.subnets["appgw"].address_prefixes[0]
    destination_address_prefix = var.subnets["vm"].address_prefixes[0]
  }

  security_rule {
    name                       = "allow-https-from-appgw-443"
    priority                   = 330
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.subnets["appgw"].address_prefixes[0]
    destination_address_prefix = var.subnets["vm"].address_prefixes[0]
  }
}

resource "azurerm_subnet_network_security_group_association" "app" {
  for_each = var.subnets["app"].nsg_enabled ? { app = var.subnets["app"] } : {}

  subnet_id                 = azurerm_subnet.this["app"].id
  network_security_group_id = azurerm_network_security_group.app_nsg["app"].id
}

resource "azurerm_subnet_network_security_group_association" "vm" {
  for_each = var.subnets["vm"].nsg_enabled ? { vm = var.subnets["vm"] } : {}

  subnet_id                 = azurerm_subnet.this["vm"].id
  network_security_group_id = azurerm_network_security_group.vm_nsg["vm"].id
}
