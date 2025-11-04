# Infrastructure Deployment Pipeline

This pipeline (`azure-pipelines-infra.yml`) handles validation and deployment of Terraform infrastructure and Helm charts.

## Setup Instructions

### 1. Azure Service Connection
Before running the pipeline, you need to create an Azure service connection in Azure DevOps:
- Go to Project Settings → Service connections → New service connection
- Select "Azure Resource Manager"
- Complete the authentication (Service principal recommended)
- Name it (e.g., `Azure-Subscription-Connection`)
- Replace `YOUR_AZURE_SUBSCRIPTION` in the pipeline with your service connection name

### 2. Pipeline Variables (Optional)
Set these in Pipeline → Variables:
- `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID (if needed)

### 3. Remote State Backend (Recommended for Production)
For production environments, configure remote state storage:

1. Create a storage account for Terraform state:
   ```bash
   az group create -n terraform-state-rg -l "Canada Central"
   az storage account create -n terraformstate -g terraform-state-rg --sku Standard_LRS
   az storage container create -n tfstate --account-name terraformstate
   ```

2. Uncomment the backend configuration lines in the pipeline file

3. Alternatively, add a `backend` block to your `infra/main.tf`:
   ```hcl
   terraform {
     backend "azurerm" {
       resource_group_name  = "terraform-state-rg"
       storage_account_name = "terraformstate"
       container_name       = "tfstate"
       key                  = "terraform.tfstate"
     }
   }
   ```

### 4. Environment Approvals (Optional)
The `DeployInfrastructure` stage uses an environment named `production`. To enable manual approvals:
- Go to Pipelines → Environments
- Create an environment named `production`
- Add approvals/checks as needed

## Pipeline Stages

1. **ValidateTerraform**: Validates Terraform syntax and creates an execution plan
2. **DeployInfrastructure**: Applies the Terraform configuration (may require approval)
3. **ValidateHelmCharts**: Validates Helm chart syntax

## Triggers

The pipeline triggers on:
- Changes to `infra/*` files
- Changes to `charts/*` files
- Pushes to the `main` branch

## Running the Pipeline

1. Commit changes to `infra/` or `charts/` directories
2. Push to the `main` branch
3. The pipeline will automatically trigger
4. Monitor progress in Azure DevOps Pipelines
