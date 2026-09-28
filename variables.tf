variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Deployment environment name (e.g. dev, prod). Drives common_tags and naming."
  type        = string
  default     = "dev"
}

variable "name_prefix" {
  description = "Short prefix applied to all resource names"
  type        = string
  default     = "azure-enterprise"
}

variable "enable_bastion" {
  description = "Deploy Azure Bastion host. Disable in dev to avoid ~$140/month charge."
  type        = bool
  default     = false
}

variable "enable_application_gateway" {
  description = "Deploy Application Gateway with WAF. Disable in dev to avoid ~$260/month charge."
  type        = bool
  default     = false
}

variable "purge_protection_enabled" {
  description = "Enable Key Vault purge protection. Must be true for production."
  type        = bool
  default     = false
}

variable "enable_resource_lock" {
  description = "Apply a CanNotDelete lock on the resource group. Set true for production."
  type        = bool
  default     = false
}

variable "plan_sku_name" {
  description = "App Service Plan SKU (e.g. B1 for dev, P2v3 for prod)"
  type        = string
  default     = "B1"
}

variable "sql_database_sku" {
  description = "SQL Database SKU name (e.g. Basic for dev, S2 for prod)"
  type        = string
  default     = "Basic"
}

variable "storage_replication_type" {
  description = "Storage Account replication type (LRS for dev, GRS for prod)"
  type        = string
  default     = "LRS"
}

variable "budget_contact_emails" {
  description = "Email addresses for budget alert and monitoring alert notifications"
  type        = list(string)
  default     = ["athomas@copado.com"]
}

variable "vm_admin_ssh_key" {
  description = "ED25519 or RSA public key written to the Linux VM's authorized_keys. Pass via terraform.tfvars or TF_VAR_vm_admin_ssh_key — do not commit the value to source control."
  type        = string
}

variable "ssl_certificate_secret_id" {
  description = "Key Vault secret ID (versioned URI) for the Application Gateway SSL certificate PFX. Required in prod when enable_application_gateway = true. Leave null in dev."
  type        = string
  default     = null
}

variable "sql_administrator_login_password" {
  description = "Password for the SQL Server administrator. Pass via TF_VAR_sql_administrator_login_password or a secrets manager — do not commit to source control."
  type      = string
  sensitive = true
  default   = null

  validation {
    condition     = var.sql_administrator_login_password != null
    error_message = "sql_administrator_login_password must be set. Pass via TF_VAR_sql_administrator_login_password or terraform.tfvars."
  }
}
