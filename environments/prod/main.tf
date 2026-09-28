# Prod environment
#
# Apply from the project root directory:
#
#   terraform apply \
#     -var-file=environments/prod/terraform.tfvars \
#     -var="vm_admin_ssh_key=$(cat ~/.ssh/azure-enterprise-vm.pub)" \
#     -var="sql_administrator_login_password=<password>"
#
# WARNING: purge_protection_enabled = true means the Key Vault cannot be recovered
# or permanently deleted for 90 days after destruction. Plan accordingly.
#
# WARNING: enable_resource_lock = true will block terraform destroy on the resource
# group until the lock is removed manually in the Azure portal or via CLI.
