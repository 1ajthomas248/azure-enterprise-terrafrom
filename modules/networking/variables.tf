variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "common_tags" {
  type    = map(string)
  default = {}
}

variable "vnet" {
  type = object({
    name          = string
    address_space = list(string)
  })
}

variable "subnets" {
  type = map(object({
    name             = string
    address_prefixes = list(string)
    nsg_enabled      = bool
  }))
}