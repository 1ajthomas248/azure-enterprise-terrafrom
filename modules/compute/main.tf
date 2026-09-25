resource "azurerm_network_interface" "vm" {
  for_each = var.vms

  name                = "${var.name_prefix}-nic-${each.key}"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.vm_subnet_id
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.tags
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each = var.vms

  name                            = "${var.name_prefix}-vm-${each.key}"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = each.value.size
  admin_username                  = each.value.admin_username
  disable_password_authentication = true

  network_interface_ids = [azurerm_network_interface.vm[each.key].id]

  admin_ssh_key {
    username   = each.value.admin_username
    public_key = each.value.admin_ssh_key
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [each.value.identity_id]
  }

  os_disk {
    caching              = each.value.os_disk_caching
    storage_account_type = each.value.os_disk_storage_account_type
    disk_size_gb         = each.value.os_disk_size_gb
  }

  source_image_reference {
    publisher = each.value.image_publisher
    offer     = each.value.image_offer
    sku       = each.value.image_sku
    version   = each.value.image_version
  }

  tags = local.tags
}

resource "azurerm_service_plan" "this" {
  count = var.app_service != null ? 1 : 0

  name                = local.names.app_service_plan
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name            = var.app_service.plan_sku_name

  tags = local.tags
}

resource "azurerm_linux_web_app" "this" {
  count = var.app_service != null ? 1 : 0

  name                      = local.names.app_service
  resource_group_name       = var.resource_group_name
  location                  = var.location
  service_plan_id           = azurerm_service_plan.this[0].id
  virtual_network_subnet_id = var.app_service.subnet_id
  https_only                = true

  identity {
    type         = "UserAssigned"
    identity_ids = [var.app_service.identity_id]
  }

  site_config {
    application_stack {
      dotnet_version      = var.app_service.app_stack.dotnet_version
      node_version        = var.app_service.app_stack.node_version
      php_version         = var.app_service.app_stack.php_version
      python_version      = var.app_service.app_stack.python_version
      java_server         = var.app_service.app_stack.java_server
      java_server_version = var.app_service.app_stack.java_server_version
      java_version        = var.app_service.app_stack.java_version
    }
  }

  app_settings = merge(
    var.app_service.app_settings,
    var.app_service.key_vault_uri != null ? { KV_URI = var.app_service.key_vault_uri } : {}
  )

  tags = local.tags
}
