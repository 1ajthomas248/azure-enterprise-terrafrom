variable "resource_group_name" {
  description = "Name of the resource group to govern"
  type        = string
}

variable "resource_group_id" {
  description = "Resource ID of the resource group — used as scope for policy assignments, the management lock, and the budget"
  type        = string
}

variable "location" {
  description = "Azure region of the resource group"
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

variable "allowed_locations" {
  description = "List of allowed Azure locations (internal names without spaces, e.g. 'eastus' not 'East US')"
  type        = list(string)
  default     = ["eastus"]
}

variable "required_tags" {
  description = "Tag names that must be present on every resource in the resource group"
  type        = list(string)
  default     = ["environment", "project"]
}

variable "enable_resource_lock" {
  description = "Place a CanNotDelete lock on the resource group. Set false in dev so terraform destroy works."
  type        = bool
  default     = false
}

variable "budget" {
  description = "Optional monthly cost budget. Set to null to skip. start_date must be the first day of a month in RFC3339 UTC format (e.g. '2026-10-01T00:00:00Z')."
  type = object({
    monthly_amount   = number
    start_date       = string
    alert_thresholds = list(number)
    contact_emails   = list(string)
  })
  default = null
}
