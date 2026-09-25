variable "sql_administrator_login_password" {
  description = "Password for the SQL Server administrator. Pass via TF_VAR_sql_administrator_login_password or a secrets manager — do not commit to source control."
  type      = string
  sensitive = true
  default   = null
}
