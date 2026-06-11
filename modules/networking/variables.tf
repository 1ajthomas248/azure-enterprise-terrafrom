variable "resource_group_name" {
  description = "Name of the resource group where the virtual network and subnets will be created"
  type        = string
}

variable "location" {
  description = "Location of the resource group and its resources"
  type        = string
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

variable "vnet" {
  description = "Virtual network configuration"
  type = object({
    name          = string
    address_space = list(string)
  })
}

variable "subnets" {
  description = "Subnet configurations"
  type = map(object({
    name             = string
    address_prefixes = list(string)
    nsg_enabled      = bool

    delegation = optional(object({
      name                    = string
      service_delegation_name = string
      actions                 = list(string)
    }))
  }))
}

variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "enable_bastion" {
  description = "Whether to deploy Azure Bastion"
  type        = bool
  default     = true
}

variable "enable_application_gateway" {
  description = "Whether to deploy Azure Application Gateway"
  type        = bool
  default     = true
}