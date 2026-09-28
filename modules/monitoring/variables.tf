variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "name_prefix" {
  description = "Prefix applied to all monitoring resource names"
  type        = string
}

variable "common_tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "log_analytics_retention_days" {
  description = "Days to retain data in the Log Analytics Workspace"
  type        = number
  default     = 30
}

variable "alert_email_receivers" {
  description = "Email addresses to notify on alert firing"
  type = list(object({
    name          = string
    email_address = string
  }))
  default = []
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault to enable diagnostics and throttle alerting on"
  type        = string
  default     = null
}

variable "sql_server_id" {
  description = "Resource ID of the SQL Server to enable security audit diagnostics on"
  type        = string
  default     = null
}

variable "database_ids" {
  description = "Map of database name keys to resource IDs for per-database diagnostics and DTU alerts"
  type        = map(string)
  default     = {}
}

variable "storage_account_id" {
  description = "Resource ID of the Storage Account to enable blob service diagnostics and availability alerts on"
  type        = string
  default     = null
}

variable "application_gateway_id" {
  description = "Resource ID of the Application Gateway to enable diagnostics and WAF alerting on"
  type        = string
  default     = null
}
