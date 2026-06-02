output "subnet_ids" {
    description = "Map of the sunet names to their respective IDs"

    value = {
        for subnet_name, subnet in azurerm_subnet.this:
        subnet_name => subnet_id
    }
}