variable "resource_group_name" {
  description = "Name of the resource group where Key Vault resources will be created"
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

variable "tenant_id" {
  description = "Azure AD tenant ID for the Key Vault"
  type        = string
}

variable "sku_name" {
  description = "SKU for the Key Vault (standard or premium)"
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "sku_name must be 'standard' or 'premium'."
  }
}

variable "enable_rbac_authorization" {
  description = "Use RBAC for data plane authorization instead of access policies"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted vaults and objects (7–90)"
  type        = number
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "soft_delete_retention_days must be between 7 and 90."
  }
}

variable "purge_protection_enabled" {
  description = "Enable purge protection to prevent permanent deletion during the retention period"
  type        = bool
  default     = true
}

variable "network_acls" {
  description = "Network ACL configuration for the Key Vault"
  type = object({
    default_action             = string
    bypass                     = string
    ip_rules                   = optional(list(string), [])
    virtual_network_subnet_ids = optional(list(string), [])
  })
  default = {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }

  validation {
    condition     = contains(["Allow", "Deny"], var.network_acls.default_action)
    error_message = "network_acls.default_action must be 'Allow' or 'Deny'."
  }

  validation {
    condition     = contains(["AzureServices", "None"], var.network_acls.bypass)
    error_message = "network_acls.bypass must be 'AzureServices' or 'None'."
  }
}

variable "private_endpoint" {
  description = "Optional private endpoint configuration. Set to null to skip private endpoint creation."
  type = object({
    subnet_id            = string
    vnet_id              = string
    create_dns_zone      = optional(bool, true)
    dns_zone_resource_group = optional(string, null)
  })
  default = null
}

variable "role_assignments" {
  description = "Map of RBAC role assignments granting access to the Key Vault"
  type = map(object({
    principal_id         = string
    role_definition_name = string
  }))
  default = {}
}
