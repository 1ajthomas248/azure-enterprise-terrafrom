output "vnet_id" {
  value = module.networking.vnet_id
}

output "subnet_ids" {
  value = module.networking.subnet_ids
}

output "application_gateway_public_ip_address" {
  value = module.networking.application_gateway_public_ip_address
}

output "identity_ids" {
  value = module.identity.identity_ids
}

output "identity_principal_ids" {
  value = module.identity.principal_ids
}

output "key_vault_id" {
  value = module.keyvault.id
}

output "key_vault_name" {
  value = module.keyvault.name
}

output "key_vault_uri" {
  value = module.keyvault.uri
}

output "vm_private_ips" {
  value = module.compute.vm_private_ips
}

output "app_service_name" {
  value = module.compute.app_service_name
}

output "app_service_default_hostname" {
  value = module.compute.app_service_default_hostname
}