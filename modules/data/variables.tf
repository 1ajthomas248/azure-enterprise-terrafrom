variable "resource_group_name" {
  description = "Name of the resource group where data resources will be created"
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

variable "private_endpoint_subnet_id" {
  description = "Subnet ID where private endpoints will be placed"
  type        = string
}

variable "vnet_id" {
  description = "VNet ID used for private DNS zone VNet links"
  type        = string
}

variable "sql" {
  description = "Optional SQL Server configuration. Set to null to skip SQL resources."
  type = object({
    administrator_login = string
    version             = optional(string, "12.0")

    azure_ad_admin = optional(object({
      login_username = string
      object_id      = string
      tenant_id      = string
    }), null)
  })
  default = null
}

variable "sql_administrator_login_password" {
  description = "Password for the SQL Server administrator. Pass via environment variable or secrets manager — do not commit to source control."
  type      = string
  sensitive = true
  default   = null
}

variable "databases" {
  description = "Map of databases to create on the SQL Server. Only used when sql is non-null."
  type = map(object({
    sku_name    = optional(string, "Basic")
    max_size_gb = optional(number, 2)
  }))
  default = {}
}

variable "storage" {
  description = "Optional Storage Account configuration. Set to null to skip storage resources."
  type = object({
    account_tier             = optional(string, "Standard")
    account_replication_type = optional(string, "LRS")

    containers = optional(map(object({
      access_type = optional(string, "private")
    })), {})
  })
  default = null

  validation {
    condition = var.storage == null || contains(
      ["Standard", "Premium"], var.storage.account_tier
    )
    error_message = "storage.account_tier must be 'Standard' or 'Premium'."
  }

  validation {
    condition = var.storage == null || contains(
      ["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.storage.account_replication_type
    )
    error_message = "storage.account_replication_type must be a valid Azure replication type."
  }
}

variable "role_assignments" {
  description = "Map of RBAC role assignments scoped to storage or SQL resources"
  type = map(object({
    principal_id         = string
    role_definition_name = string
    service              = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.role_assignments : contains(["sql", "storage"], v.service)
    ])
    error_message = "role_assignments[*].service must be 'sql' or 'storage'."
  }
}
