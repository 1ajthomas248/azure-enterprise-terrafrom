# App Service diagnostic settings and metric alerts live here (not in the monitoring module)
# to avoid a circular dependency: module.compute needs module.monitoring for the App Insights
# connection string, so module.monitoring cannot also depend on module.compute.

resource "azurerm_monitor_diagnostic_setting" "app_service" {
  count = module.compute.app_service_id != null ? 1 : 0

  name                       = "azure-enterprise-app-service-diag"
  target_resource_id         = module.compute.app_service_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  enabled_log { category = "AppServiceHTTPLogs" }
  enabled_log { category = "AppServiceConsoleLogs" }
  enabled_log { category = "AppServiceAppLogs" }
  enabled_log { category = "AppServiceAuditLogs" }

  enabled_metric { category = "AllMetrics" }
}

resource "azurerm_monitor_metric_alert" "app_service_http_5xx" {
  count = module.compute.app_service_id != null ? 1 : 0

  name                = "azure-enterprise-alert-app-5xx"
  resource_group_name = azurerm_resource_group.azure_enterprise_project.name
  scopes              = [module.compute.app_service_id]
  description         = "App Service HTTP 5xx error rate exceeds 10 errors per 15 minutes"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 10
  }

  action {
    action_group_id = module.monitoring.action_group_id
  }

  tags = {
    environment = "dev"
    project     = "azure-enterprise"
  }
}

resource "azurerm_monitor_metric_alert" "app_service_response_time" {
  count = module.compute.app_service_id != null ? 1 : 0

  name                = "azure-enterprise-alert-app-latency"
  resource_group_name = azurerm_resource_group.azure_enterprise_project.name
  scopes              = [module.compute.app_service_id]
  description         = "App Service average response time exceeds 2 seconds"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "HttpResponseTime"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 2
  }

  action {
    action_group_id = module.monitoring.action_group_id
  }

  tags = {
    environment = "dev"
    project     = "azure-enterprise"
  }
}

resource "azurerm_monitor_metric_alert" "vm_cpu" {
  for_each = module.compute.vm_ids

  name                = "azure-enterprise-alert-vm-${each.key}-cpu"
  resource_group_name = azurerm_resource_group.azure_enterprise_project.name
  scopes              = [each.value]
  description         = "VM CPU percentage exceeds 85%"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = module.monitoring.action_group_id
  }

  tags = {
    environment = "dev"
    project     = "azure-enterprise"
  }
}

resource "azurerm_monitor_metric_alert" "vm_available_memory" {
  for_each = module.compute.vm_ids

  name                = "azure-enterprise-alert-vm-${each.key}-memory"
  resource_group_name = azurerm_resource_group.azure_enterprise_project.name
  scopes              = [each.value]
  description         = "VM available memory has dropped below 512 MB"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Available Memory Bytes"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 536870912
  }

  action {
    action_group_id = module.monitoring.action_group_id
  }

  tags = {
    environment = "dev"
    project     = "azure-enterprise"
  }
}
