# Dev environment
#
# Apply from the project root directory:
#
#   terraform apply \
#     -var-file=environments/dev/terraform.tfvars \
#     -var="vm_admin_ssh_key=$(cat ~/.ssh/azure-enterprise-vm.pub)" \
#     -var="sql_administrator_login_password=<password>"
#
# Bastion and Application Gateway are disabled in dev to reduce cost (~$400/month saving).
# Purge protection and resource locks are also off to allow easy teardown.
