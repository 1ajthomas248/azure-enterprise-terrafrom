# azure-enterprise-terraform

An enterprise infrastructure project for Azure, automated with Terraform. Deploys a production-ready topology including networking, compute, data, security, monitoring, and governance — all wired together through managed identities with no shared credentials.

## Architecture

```
Internet
   │
   ▼
Application Gateway (WAF_v2)   ←── HTTPS termination (prod)
   │  HTTP → HTTPS redirect
   ▼
┌─────────────────────────────────────────────────────┐
│  VNet (10.0.0.0/16)                                 │
│                                                     │
│  app-subnet      (10.0.1.0/24)  App Service         │
│  vm-subnet       (10.0.2.0/24)  Linux VM            │
│  private-ep      (10.0.3.0/24)  Private Endpoints   │
│  appgw-subnet    (10.0.4.0/24)  Application Gateway │
│  AzureBastionSubnet (10.0.5.0/24)  Bastion Host     │
└─────────────────────────────────────────────────────┘
         │                    │
         ▼                    ▼
   Key Vault             SQL Server + Storage Account
   (private endpoint)   (private endpoints, no public access)
         │
         ▼
   Log Analytics + Application Insights
```

### Modules

| Module | Resources |
|--------|-----------|
| `networking` | VNet, 5 subnets, NSGs, Application Gateway (WAF_v2), Azure Bastion |
| `identity` | User-assigned managed identities (app, vm, appgw) |
| `keyvault` | Key Vault (RBAC), private endpoint, role assignments |
| `compute` | Linux VM, App Service (VNet-integrated) |
| `data` | SQL Server + database, Storage Account, private endpoints, DNS zones |
| `monitoring` | Log Analytics workspace, Application Insights, metric alerts |
| `governance` | Azure Policy (allowed locations, required tags), budget alert, resource lock |

All service-to-service access uses managed identities and Azure RBAC — no connection strings or access keys.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.4
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.50
- An active Azure subscription
- Owner or Contributor + User Access Administrator on the subscription (role assignments are created)

## Authentication

Terraform uses the Azure CLI credential by default — no service principal is needed for local development.

```bash
az login
az account set --subscription "<your-subscription-id>"
```

## SSH Key Setup

The Linux VM requires an ED25519 public key:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/azure-enterprise-vm
# Press Enter twice for no passphrase (or set one)
```

The public key path (`~/.ssh/azure-enterprise-vm.pub`) is passed at apply time — see below.

## Applying per Environment

### Dev

```bash
terraform apply \
  -var-file=environments/dev/terraform.tfvars \
  -var="vm_admin_ssh_key=$(cat ~/.ssh/azure-enterprise-vm.pub)" \
  -var="sql_administrator_login_password=<password>"
```

Dev has `enable_bastion = false` and `enable_application_gateway = false` to avoid ~$400/month in optional infrastructure costs.

### Prod

```bash
terraform apply \
  -var-file=environments/prod/terraform.tfvars \
  -var="vm_admin_ssh_key=$(cat ~/.ssh/azure-enterprise-vm.pub)" \
  -var="sql_administrator_login_password=<password>" \
  -var="ssl_certificate_secret_id=https://<vault-name>.vault.azure.net/secrets/<cert-name>/<version>"
```

Prod enables Bastion, Application Gateway (WAF), GRS storage replication, Key Vault purge protection, and a CanNotDelete resource lock.

## Variable Reference

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `location` | `string` | `"East US"` | Azure region for all resources |
| `environment` | `string` | `"dev"` | Deployment environment name; drives tags and naming |
| `name_prefix` | `string` | `"azure-enterprise"` | Short prefix applied to all resource names |
| `enable_bastion` | `bool` | `false` | Deploy Azure Bastion (~$140/month) |
| `enable_application_gateway` | `bool` | `false` | Deploy Application Gateway with WAF_v2 (~$260/month) |
| `purge_protection_enabled` | `bool` | `false` | Enable Key Vault purge protection (required for prod) |
| `enable_resource_lock` | `bool` | `false` | Apply CanNotDelete lock on the resource group |
| `plan_sku_name` | `string` | `"B1"` | App Service Plan SKU (`B1` dev, `P2v3` prod) |
| `sql_database_sku` | `string` | `"Basic"` | SQL Database SKU (`Basic` dev, `S2` prod) |
| `storage_replication_type` | `string` | `"LRS"` | Storage replication (`LRS` dev, `GRS` prod) |
| `budget_contact_emails` | `list(string)` | `["athomas@copado.com"]` | Emails for budget and monitoring alerts |
| `vm_admin_ssh_key` | `string` | *(required)* | ED25519 public key for the Linux VM |
| `sql_administrator_login_password` | `string` | *(required)* | SQL Server administrator password |
| `ssl_certificate_secret_id` | `string` | `null` | Key Vault secret URI for the AppGW SSL certificate PFX (prod only) |

## Secrets — Never Commit

The following values must never be committed to source control. They are covered by `.gitignore` but are called out explicitly here:

- `terraform.tfvars` (root and any environment-local copy)
- `sql_administrator_login_password` — pass via `-var` flag or `TF_VAR_sql_administrator_login_password`
- `vm_admin_ssh_key` — pass via `-var` flag or `TF_VAR_vm_admin_ssh_key`
- `ssl_certificate_secret_id` — the URI itself is not secret, but the PFX stored at that URI is; keep the PFX out of source control

## HTTPS / SSL (Prod)

When `enable_application_gateway = true`, the gateway performs HTTPS termination. It pulls the SSL certificate from Key Vault using its own managed identity (`appgw`). The identity is automatically granted **Key Vault Secrets User** by the keyvault module.

To provision:
1. Upload your PFX as a Key Vault secret (base64-encoded).
2. Copy the versioned secret URI from the Azure portal or CLI.
3. Pass it as `ssl_certificate_secret_id` at apply time (see Prod example above).

HTTP traffic is permanently redirected (301) to HTTPS at the gateway level.
