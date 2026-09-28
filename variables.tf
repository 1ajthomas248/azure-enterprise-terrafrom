variable "vm_admin_ssh_key" {
  description = "ED25519 or RSA public key written to the Linux VM's authorized_keys. Pass via terraform.tfvars or TF_VAR_vm_admin_ssh_key — do not commit the value to source control."
  type        = string
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
