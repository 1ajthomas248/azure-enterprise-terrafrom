# ── Policy definitions ────────────────────────────────────────────────────────

data "azurerm_policy_definition" "allowed_locations" {
  display_name = "Allowed locations"
}

data "azurerm_policy_definition" "require_tag" {
  display_name = "Require a tag on resources"
}

data "azurerm_policy_definition" "storage_https" {
  display_name = "Secure transfer to storage accounts should be enabled"
}

data "azurerm_policy_definition" "kv_purge_protection" {
  display_name = "Azure Key Vault should have purge protection enabled"
}

data "azurerm_policy_definition" "sql_auditing" {
  display_name = "Auditing on SQL server should be enabled"
}

# ── Policy assignments ────────────────────────────────────────────────────────

resource "azurerm_resource_group_policy_assignment" "allowed_locations" {
  name                 = "${var.name_prefix}-allowed-locations"
  resource_group_id    = var.resource_group_id
  policy_definition_id = data.azurerm_policy_definition.allowed_locations.id
  display_name         = "Allowed locations"

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = var.allowed_locations
    }
  })
}

resource "azurerm_resource_group_policy_assignment" "require_tag" {
  for_each = toset(var.required_tags)

  name                 = "${var.name_prefix}-tag-${each.key}"
  resource_group_id    = var.resource_group_id
  policy_definition_id = data.azurerm_policy_definition.require_tag.id
  display_name         = "Require tag: ${each.key}"

  parameters = jsonencode({
    tagName = {
      value = each.key
    }
  })
}

resource "azurerm_resource_group_policy_assignment" "storage_https" {
  name                 = "${var.name_prefix}-storage-https"
  resource_group_id    = var.resource_group_id
  policy_definition_id = data.azurerm_policy_definition.storage_https.id
  display_name         = "Storage accounts: require secure transfer"
}

resource "azurerm_resource_group_policy_assignment" "kv_purge_protection" {
  name                 = "${var.name_prefix}-kv-purge"
  resource_group_id    = var.resource_group_id
  policy_definition_id = data.azurerm_policy_definition.kv_purge_protection.id
  display_name         = "Key Vault: require purge protection"
}

resource "azurerm_resource_group_policy_assignment" "sql_auditing" {
  name                 = "${var.name_prefix}-sql-audit"
  resource_group_id    = var.resource_group_id
  policy_definition_id = data.azurerm_policy_definition.sql_auditing.id
  display_name         = "SQL Server: require auditing"
}

# ── Resource lock ─────────────────────────────────────────────────────────────

resource "azurerm_management_lock" "resource_group" {
  count = var.enable_resource_lock ? 1 : 0

  name       = "${var.name_prefix}-rg-lock"
  scope      = var.resource_group_id
  lock_level = "CanNotDelete"
  notes      = "Managed by Terraform. Remove via Terraform before destroying this resource group."
}

# ── Cost budget ───────────────────────────────────────────────────────────────

resource "azurerm_consumption_budget_resource_group" "this" {
  count = var.budget != null ? 1 : 0

  name              = "${var.name_prefix}-budget"
  resource_group_id = var.resource_group_id
  amount            = var.budget.monthly_amount
  time_grain        = "Monthly"

  time_period {
    start_date = var.budget.start_date
  }

  dynamic "notification" {
    for_each = var.budget.alert_thresholds

    content {
      enabled        = true
      threshold      = notification.value
      operator       = "GreaterThanOrEqualTo"
      threshold_type = "Actual"
      contact_emails = var.budget.contact_emails
    }
  }
}
