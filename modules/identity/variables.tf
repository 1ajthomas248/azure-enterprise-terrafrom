variable "resource_group_name" {
  description = "Name of the resource group where identity resources will be created"
  type        = string
}

variable "location" {
  description = "Location of the resource group and its resources"
  type        = string
}

variable "common_tags" {
  description = "Common tags applied to resources"
  type        = map(string)
  default     = {}
}

variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "identities" {
  description = "Map of user assigned managed identities to create"
  type = map(object({
    name_suffix = string
  }))
}