output "vnet_id" {
  value = module.networking.vnet_id
}

output "subnet_ids" {
  value = module.networking.subnet_ids
}

output "application_gateway_public_ip_address" {
  value = module.networking.application_gateway_public_ip_address
}