variable "resource_group_name" {
  description = "Name of the resource group where compute resources will be created"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "vm_subnet_id" {
  description = "Subnet ID for VM network interfaces. Required when vms is non-empty."
  type        = string
  default     = null
}

variable "vms" {
  description = "Map of Linux VMs to create. Key is used as a name suffix."
  type = map(object({
    size           = string
    admin_username = string
    admin_ssh_key  = string
    identity_id    = string

    os_disk_caching              = optional(string, "ReadWrite")
    os_disk_storage_account_type = optional(string, "Premium_LRS")
    os_disk_size_gb              = optional(number, null)

    image_publisher = optional(string, "Canonical")
    image_offer     = optional(string, "0001-com-ubuntu-server-jammy")
    image_sku       = optional(string, "22_04-lts-gen2")
    image_version   = optional(string, "latest")
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.vms : contains(["ReadWrite", "ReadOnly", "None"], v.os_disk_caching)
    ])
    error_message = "os_disk_caching must be 'ReadWrite', 'ReadOnly', or 'None'."
  }
}

variable "app_service" {
  description = "Optional App Service configuration. Set to null to skip App Service creation."
  type = object({
    plan_sku_name = optional(string, "B1")
    subnet_id     = string
    identity_id   = string
    app_settings  = optional(map(string), {})
    key_vault_uri = optional(string, null)

    app_stack = object({
      dotnet_version      = optional(string)
      node_version        = optional(string)
      php_version         = optional(string)
      python_version      = optional(string)
      java_server         = optional(string)
      java_server_version = optional(string)
      java_version        = optional(string)
    })
  })
  default = null
}
