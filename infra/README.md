# Infrastructure Deployment

This directory contains a **single set of Terraform configuration files** that manages all environments (dev, stage, prod). Each environment folder contains only the environment-specific variable files (`.tfvars`) and backend configuration files.

## Directory Structure

```
infra/
├── bootstrap/          # Bootstrap configuration for Terraform state storage
│   └── main.tf        # Creates storage account for Terraform state (one-time setup)
├── main.tf            # Shared Terraform configuration for all environments
├── provider.tf        # Shared provider configuration with backend
├── outputs.tf         # Shared output definitions
├── dev/               # Development environment configuration
│   ├── dev.tfvars     # Dev-specific variable values
│   └── backend.conf   # Backend config for dev state
├── stage/             # Staging environment configuration
│   ├── stage.tfvars   # Stage-specific variable values
│   └── backend.conf   # Backend config for stage state
└── prod/              # Production environment configuration
    ├── prod.tfvars    # Prod-specific variable values
    └── backend.conf   # Backend config for prod state
```

## State Storage Architecture

**All environments use the same storage account** but with different state file keys:

```
Storage Account: tfstatemcda2025
Container: tfstate
├── dev/terraform.tfstate     ← Dev environment state
├── stage/terraform.tfstate   ← Stage environment state
└── prod/terraform.tfstate    ← Prod environment state
```

This approach provides:
- ✅ **DRY Principle**: One set of Terraform files for all environments
- ✅ **Cost efficiency**: One storage account for all environments
- ✅ **State isolation**: Separate state files prevent cross-environment issues
- ✅ **Easy maintenance**: Update infrastructure code once, apply to all environments
- ✅ **Environment-specific configs**: Each folder only contains environment-specific values

## Environment-Specific Configurations

Each environment folder contains a `.tfvars` file with environment-specific values:

### Development (`dev/dev.tfvars`)
- **AKS Node Count**: 1 node
- **ACR SKU**: Basic
- **Key Vault**: Standard protection (7 day retention)
- **RBAC**: Disabled

### Staging (`stage/stage.tfvars`)
- **AKS Node Count**: 2 nodes
- **ACR SKU**: Standard
- **Key Vault**: Standard protection (7 day retention)
- **RBAC**: Disabled

### Production (`prod/prod.tfvars`)
- **AKS Node Count**: 3 nodes (with auto-scaling: 3-10)
- **ACR SKU**: Premium (with geo-replication to East US)
- **Key Vault**: Soft delete (90 days), purge protection enabled
- **RBAC**: Enabled on AKS

## Setup Instructions

### 1. Bootstrap Terraform State Storage (One-time setup)

First, create the storage account for Terraform state:

```bash
cd infra/bootstrap
terraform init
terraform plan
terraform apply
```

This creates:
- Resource group: `terraform-state-rg`
- Storage account: `tfstatemcda2025` (update the name in bootstrap/main.tf if needed)
- Container: `tfstate`

**Important**: Update the `storage_account_name` in `bootstrap/main.tf` to something globally unique (3-24 characters, lowercase alphanumeric).

### 2. Update Backend Configuration

After bootstrap, update the `storage_account_name` in each environment's `backend.conf`:
- `dev/backend.conf`
- `stage/backend.conf`
- `prod/backend.conf`

Replace `tfstatemcda2025` with the actual storage account name you created.

### 3. Update Tenant ID

Update the `tenant_id` in each environment's `.tfvars` file:
- `dev/dev.tfvars`
- `stage/stage.tfvars`
- `prod/prod.tfvars`

Replace `<tenant-id>` with your Azure AD tenant ID.

### 4. Deploy to an Environment

To deploy to a specific environment, run Terraform from the root `infra/` directory with the appropriate backend config and var file:

```bash
# Development
cd infra
terraform init -backend-config=dev/backend.conf
terraform plan -var-file=dev/dev.tfvars
terraform apply -var-file=dev/dev.tfvars

# Staging
terraform init -backend-config=stage/backend.conf
terraform plan -var-file=stage/stage.tfvars
terraform apply -var-file=stage/stage.tfvars

# Production
terraform init -backend-config=prod/backend.conf
terraform plan -var-file=prod/prod.tfvars
terraform apply -var-file=prod/prod.tfvars
```

**Important**: When switching between environments, you **must** re-run `terraform init -backend-config={env}/backend.conf` to switch the backend state location.

## Resource Naming

Resources are automatically named with the environment suffix based on the `environment` variable:
- Resource Groups: `mcda-{env}-rg` (e.g., `mcda-dev-rg`)
- AKS Clusters: `mcda-{env}-aks` (e.g., `mcda-dev-aks`)
- ACR: `mcda{env}acr` (e.g., `mcdadevacr`)
- Key Vaults: `mcda-{env}-kv` (e.g., `mcda-dev-kv`)

## Outputs

Each environment provides the following outputs:
- `environment`: The environment name
- `resource_group_name`: Resource group name
- `aks_cluster_name`: AKS cluster name
- `kube_config`: Kubernetes config (sensitive)
- `acr_login_server`: ACR login server URL
- `acr_name`: ACR name
- `key_vault_name`: Key Vault name
- `key_vault_uri`: Key Vault URI

## Benefits of This Structure

1. **DRY Principle**: One source of truth for all infrastructure code
2. **Consistency**: Same resource definitions across all environments
3. **Easier Maintenance**: Update once, apply to all environments
4. **Version Control**: Easier to track changes across environments
5. **Flexibility**: Easy to add new environments by creating new `.tfvars` and `backend.conf` files
6. **Cost Efficiency**: Single storage account for all state files
7. **Clear Separation**: Environment-specific values are clearly separated in folder structure

## Best Practices

1. **Always run terraform plan** before apply, especially in production
2. **Review the plan output** carefully to understand what will change
3. **Use separate service principals** for each environment if possible
4. **Enable approval gates** in your CI/CD pipeline for production deployments
5. **Keep the bootstrap storage account separate** from application resources
6. **Enable blob versioning** on the storage account (already configured) for state file recovery
7. **Always specify backend config** when initializing to avoid state conflicts
8. **Work from the root infra/ directory** - all Terraform commands should be run from there

## Troubleshooting

### Storage Account Name Already Exists
Storage account names must be globally unique. Update the `storage_account_name` in `bootstrap/main.tf` and try again.

### ACR Name Conflicts
ACR names must be globally unique. The name is generated from the environment variable. If you get a conflict, you can modify the `acr_name` local in `main.tf` to add a unique suffix.

### Backend Configuration Error
Ensure you've:
1. Run the bootstrap configuration first
2. Updated the `storage_account_name` in all environment `backend.conf` files
3. Run `terraform init -backend-config={env}/backend.conf` after updating backend configuration
4. Use the correct backend config file for the environment you're working with

### Wrong Environment Applied
Always double-check:
- You're using the correct `.tfvars` file (`-var-file=dev/dev.tfvars`)
- You've initialized with the correct backend config (`-backend-config=dev/backend.conf`)
- Review the plan output to verify the environment name matches your intent

### State Locked Error
If you get a state lock error, it means another Terraform operation is running. Wait for it to complete, or if it's stuck, you can force unlock:
```bash
terraform force-unlock <LOCK_ID>
```

## Working with Multiple Environments

Since all environments share the same Terraform configuration but use different state files:
- You can work on different environments by switching backend configs and var files
- Changes to `main.tf`, `provider.tf`, or `outputs.tf` affect all environments
- Environment-specific changes are made only in the `.tfvars` files
- Each environment's state is completely isolated in the shared storage account
