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

  dynamic "delegation" {
    for_each = each.value.delegation == null ? [] : [each.value.delegation]

    content {
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.service_delegation_name
        actions = delegation.value.actions
      }
    }
  }
}

resource "azurerm_network_security_group" "app_nsg" {
  for_each = var.subnets["app"].nsg_enabled ? { app = var.subnets["app"] } : {}

  name                = local.names.app_nsg
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

  name                = local.names.vm_nsg
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

resource "azurerm_public_ip" "bastion" {
  count = var.enable_bastion ? 1 : 0

  name                = local.names.bastion_pip
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.tags
}

resource "azurerm_bastion_host" "this" {
  count = var.enable_bastion ? 1 : 0

  name                = local.names.bastion
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                 = "default"
    subnet_id            = azurerm_subnet.this["bastion"].id
    public_ip_address_id = azurerm_public_ip.bastion[0].id
  }

  tags = local.tags
}

resource "azurerm_public_ip" "application_gateway" {
  count = var.enable_application_gateway ? 1 : 0

  name                = local.names.appgw_pip
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.tags
}

resource "azurerm_application_gateway" "this" {
  count = var.enable_application_gateway ? 1 : 0

  name                = local.names.appgw
  resource_group_name = var.resource_group_name
  location            = var.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "appgw-ip-configuration"
    subnet_id = azurerm_subnet.this["appgw"].id
  }

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.application_gateway[0].id
  }

  frontend_port {
    name = "http"
    port = 80
  }

  backend_address_pool {
    name = "app-backend-pool"
  }

  backend_http_settings {
    name                  = "http"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = "http"
    frontend_ip_configuration_name = "public"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "http-to-app-backend"
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = "http"
    backend_address_pool_name  = "app-backend-pool"
    backend_http_settings_name = "http"
  }

  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.2"
  }

  tags = local.tags
}