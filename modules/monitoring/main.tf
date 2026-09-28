locals {
  workspace_name     = "${var.name_prefix}-law"
  app_insights_name  = "${var.name_prefix}-appi"
  action_group_name  = "${var.name_prefix}-ag"
  action_group_short = substr(replace(var.name_prefix, "-", ""), 0, 12)
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = local.workspace_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_analytics_retention_days

  tags = var.common_tags
}

resource "azurerm_application_insights" "this" {
  name                = local.app_insights_name
  resource_group_name = var.resource_group_name
  location            = var.location
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"

  tags = var.common_tags
}

resource "azurerm_monitor_action_group" "this" {
  name                = local.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = local.action_group_short

  dynamic "email_receiver" {
    for_each = var.alert_email_receivers
    content {
      name          = email_receiver.value.name
      email_address = email_receiver.value.email_address
    }
  }

  tags = var.common_tags
}

# ── Diagnostic settings ───────────────────────────────────────────────────────

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  count = var.key_vault_id != null ? 1 : 0

  name                       = "${var.name_prefix}-keyvault-diag"
  target_resource_id         = var.key_vault_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log { category = "AuditEvent" }
  enabled_log { category = "AzurePolicyEvaluationDetails" }

  enabled_metric { category = "AllMetrics" }
}

resource "azurerm_monitor_diagnostic_setting" "sql_server" {
  count = var.sql_server_id != null ? 1 : 0

  name                       = "${var.name_prefix}-sql-server-diag"
  target_resource_id         = var.sql_server_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log { category = "SQLSecurityAuditEvents" }
  enabled_log { category = "DevOpsOperationsAudit" }
}

resource "azurerm_monitor_diagnostic_setting" "sql_database" {
  for_each = var.database_ids

  name                       = "${var.name_prefix}-sqldb-${each.key}-diag"
  target_resource_id         = each.value
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log { category = "SQLInsights" }
  enabled_log { category = "AutomaticTuning" }
  enabled_log { category = "QueryStoreRuntimeStatistics" }
  enabled_log { category = "QueryStoreWaitStatistics" }
  enabled_log { category = "Errors" }
  enabled_log { category = "DatabaseWaitStatistics" }
  enabled_log { category = "Timeouts" }
  enabled_log { category = "Blocks" }
  enabled_log { category = "Deadlocks" }

  enabled_metric { category = "Basic" }
}

resource "azurerm_monitor_diagnostic_setting" "storage_blob" {
  count = var.storage_account_id != null ? 1 : 0

  name                       = "${var.name_prefix}-storage-blob-diag"
  target_resource_id         = "${var.storage_account_id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log { category = "StorageRead" }
  enabled_log { category = "StorageWrite" }
  enabled_log { category = "StorageDelete" }

  enabled_metric { category = "Transaction" }
}

resource "azurerm_monitor_diagnostic_setting" "app_service" {
  count = var.app_service_id != null ? 1 : 0

  name                       = "${var.name_prefix}-appservice-diag"
  target_resource_id         = var.app_service_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log { category = "AppServiceHTTPLogs" }
  enabled_log { category = "AppServiceConsoleLogs" }
  enabled_log { category = "AppServiceAppLogs" }
  enabled_log { category = "AppServiceAuditLogs" }
  enabled_log { category = "AppServicePlatformLogs" }

  enabled_metric { category = "AllMetrics" }
}

resource "azurerm_monitor_diagnostic_setting" "vm" {
  for_each = var.vm_ids

  name                       = "${var.name_prefix}-vm-${each.key}-diag"
  target_resource_id         = each.value
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_metric { category = "AllMetrics" }
}

resource "azurerm_monitor_diagnostic_setting" "application_gateway" {
  count = var.application_gateway_id != null ? 1 : 0

  name                       = "${var.name_prefix}-appgw-diag"
  target_resource_id         = var.application_gateway_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  enabled_log { category = "ApplicationGatewayAccessLog" }
  enabled_log { category = "ApplicationGatewayPerformanceLog" }
  enabled_log { category = "ApplicationGatewayFirewallLog" }

  enabled_metric { category = "AllMetrics" }
}

# ── Metric alerts ─────────────────────────────────────────────────────────────

resource "azurerm_monitor_metric_alert" "key_vault_throttle" {
  count = var.key_vault_id != null ? 1 : 0

  name                = "${var.name_prefix}-alert-kv-throttle"
  resource_group_name = var.resource_group_name
  scopes              = [var.key_vault_id]
  description         = "Key Vault requests are being throttled (HTTP 429)"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.KeyVault/vaults"
    metric_name      = "ServiceApiResult"
    aggregation      = "Count"
    operator         = "GreaterThan"
    threshold        = 0

    dimension {
      name     = "StatusCode"
      operator = "Include"
      values   = ["429"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }

  tags = var.common_tags
}

resource "azurerm_monitor_metric_alert" "sql_dtu" {
  for_each = var.database_ids

  name                = "${var.name_prefix}-alert-sqldb-${each.key}-dtu"
  resource_group_name = var.resource_group_name
  scopes              = [each.value]
  description         = "SQL Database DTU consumption exceeds 85%"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Sql/servers/databases"
    metric_name      = "dtu_consumption_percent"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }

  tags = var.common_tags
}

resource "azurerm_monitor_metric_alert" "storage_availability" {
  count = var.storage_account_id != null ? 1 : 0

  name                = "${var.name_prefix}-alert-storage-availability"
  resource_group_name = var.resource_group_name
  scopes              = [var.storage_account_id]
  description         = "Storage Account availability has dropped below 99%"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "Availability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 99
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }

  tags = var.common_tags
}

resource "azurerm_monitor_metric_alert" "waf_blocked_requests" {
  count = var.application_gateway_id != null ? 1 : 0

  name                = "${var.name_prefix}-alert-waf-blocked"
  resource_group_name = var.resource_group_name
  scopes              = [var.application_gateway_id]
  description         = "WAF blocked request count has spiked (dynamic threshold)"
  severity            = 3
  frequency           = "PT5M"
  window_size         = "PT15M"

  dynamic_criteria {
    metric_namespace  = "Microsoft.Network/applicationGateways"
    metric_name       = "BlockedReqCount"
    aggregation       = "Total"
    operator          = "GreaterThan"
    alert_sensitivity = "Medium"
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }

  tags = var.common_tags
}
