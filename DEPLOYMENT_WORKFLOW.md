# Complete Deployment Workflow

This document explains the complete deployment process using Azure DevOps pipelines and Terraform.

## 🏗️ System Overview

```
┌─────────────────────────────────────────────────────────────┐
│ 1. CODE PUSH                                                 │
│    Git push to main branch                                   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. BUILD PIPELINE (azure-pipelines-infra.yml)               │
│    Automatic - Runs on every push                           │
│                                                              │
│    Stage 1: ValidateTerraform                               │
│      • Runs terraform init for dev/stage/prod               │
│      • Creates .terraform.lock.hcl                          │
│      • Runs terraform plan                                  │
│      • Publishes artifacts: tfplan-{env} + lock file        │
│                                                              │
│    Stage 2: ValidateHelmCharts                              │
│      • Lints Helm charts                                    │
│      • Validates templates for all environments             │
│                                                              │
│    Stage 3: PackageCharts                                   │
│      • Packages Helm charts                                 │
│      • Includes deploy.sh script                            │
│      • Publishes artifact: helm-charts                      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. ARTIFACTS CREATED                                         │
│    ✓ tfplan-dev (plan + .terraform.lock.hcl)                │
│    ✓ tfplan-stage (plan + .terraform.lock.hcl)              │
│    ✓ tfplan-prod (plan + .terraform.lock.hcl)               │
│    ✓ helm-charts (packaged charts + deploy.sh)              │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. APPLY INFRASTRUCTURE (Manual or Release Pipeline)        │
│    Download tfplan-dev artifact                             │
│    Restore .terraform.lock.hcl                              │
│    Run: terraform apply tfplan-dev                          │
│                                                              │
│    Creates:                                                  │
│      • AKS Cluster                                          │
│      • ACR, KeyVault, CosmosDB                              │
│      • Prometheus + Grafana (cluster-tools.tf)              │
│      • Nginx Ingress (cluster-tools.tf)                     │
│      • Grafana Cloud Alloy (graphana-k8s-monitoring.tf)     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. DEPLOY APPLICATION (Manual or Automated)                 │
│    Download helm-charts artifact                            │
│    Run: ./deploy.sh dev <image-tag>                         │
│                                                              │
│    Deploys:                                                  │
│      • Backend (FastAPI)                                    │
│      • Frontend (React)                                     │
│      • Ingress routing                                      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. MONITOR                                                   │
│    Local: ./scripts/access-services.sh grafana              │
│    Cloud: https://YOUR-STACK.grafana.net                    │
└─────────────────────────────────────────────────────────────┘
```

## 📋 Step-by-Step: First Time Setup

### Prerequisites

```bash
# Install tools
brew install azure-cli terraform kubectl helm docker

# Login to Azure
az login

# Verify you're authenticated
az account show
```

### Step 1: Initialize and Deploy Infrastructure

```bash
# Clone repository
git clone <your-repo-url>
cd aks_spa_fastapi_mongo

# Navigate to infrastructure
cd infra

# Initialize Terraform
terraform init -backend-config="dev/backend.conf"

# OPTION A: Deploy without Grafana Cloud (simplest)
terraform apply -var-file="dev/dev.tfvars"

# OPTION B: Deploy with Grafana Cloud monitoring
# First, create grafana-cloud-secrets.tfvars (see GRAFANA_CLOUD_SETUP.md)
terraform apply \
  -var-file="dev/dev.tfvars" \
  -var-file="dev/grafana-cloud-secrets.tfvars"

# Wait ~15-20 minutes for Azure to provision resources
```

**What gets created:**
- ✅ Resource Group: `mcda-dev-rg`
- ✅ AKS Cluster: `mcda-dev-aks`
- ✅ Container Registry: `mcdadevacr.azurecr.io`
- ✅ KeyVault: `mcda-dev-kv`
- ✅ CosmosDB: `cosmosdbdev`
- ✅ Prometheus + Grafana (in AKS cluster)
- ✅ Nginx Ingress Controller
- ✅ CSI Secrets Driver
- ✅ Grafana Alloy (if Cloud credentials provided)

### Step 2: Get Infrastructure Outputs

```bash
# View all outputs
terraform output

# Important outputs:
terraform output acr_login_server
terraform output aks_cluster_name
terraform output key_vault_name
terraform output grafana_url
```

### Step 3: Build and Push Docker Images

```bash
# Get ACR credentials
ACR_NAME=$(terraform output -raw acr_name)
az acr login --name $ACR_NAME

# Build backend
cd ../backend
docker build -t ${ACR_NAME}.azurecr.io/backend:v1.0.0 .
docker push ${ACR_NAME}.azurecr.io/backend:v1.0.0

# Build frontend (if you have Dockerfile)
cd ../frontend
docker build -t ${ACR_NAME}.azurecr.io/frontend:v1.0.0 .
docker push ${ACR_NAME}.azurecr.io/frontend:v1.0.0
```

### Step 4: Deploy Application

```bash
# Navigate to charts directory
cd ../charts

# Deploy to dev environment
./deploy.sh dev v1.0.0

# Script will:
#   • Read Terraform outputs
#   • Connect to AKS
#   • Deploy via Helm
#   • Wait for pods to be ready
```

### Step 5: Access Monitoring

```bash
# Access Grafana
cd ../scripts
./access-services.sh grafana
# Open: http://localhost:3000 (admin/admin)

# Or access both Grafana and Prometheus
./access-services.sh all
```

---

## 🔄 Subsequent Deployments (Application Updates)

Once infrastructure is deployed, you only need to update applications:

```bash
# 1. Build new image
cd backend
docker build -t ${ACR_NAME}.azurecr.io/backend:v1.0.1 .
docker push ${ACR_NAME}.azurecr.io/backend:v1.0.1

# 2. Deploy new version
cd ../charts
./deploy.sh dev v1.0.1

# Done! (~2 minutes)
```

---

## 🔧 Using Azure DevOps Pipeline Artifacts

### When Pipeline Runs Automatically

```bash
# 1. Push code
git add .
git commit -m "Update infrastructure"
git push origin main

# 2. Pipeline runs automatically (azure-pipelines-infra.yml)
#    • Creates Terraform plans
#    • Validates Helm charts
#    • Publishes artifacts

# 3. In Azure DevOps, go to the completed run
#    • Click on the run
#    • Go to "Related" → "Published"
#    • Download artifacts

# 4. Apply infrastructure from artifact
cd infra

# Extract downloaded artifact
unzip ~/Downloads/tfplan-dev.zip -d ~/Downloads/tfplan-dev

# Restore lock file
cp ~/Downloads/tfplan-dev/.terraform.lock.hcl .terraform.lock.hcl

# Initialize with lock file
terraform init -backend-config="dev/backend.conf"

# Apply the plan
terraform apply ~/Downloads/tfplan-dev/tfplan-dev

# 5. Deploy application from helm-charts artifact
cd ~/Downloads/helm-charts
chmod +x deploy.sh
./deploy.sh dev v1.0.0
```

---

## 🎯 Variable Values - Where They Come From

### **Terraform Variables** (You Set These)

| Variable | Source | How to Set |
|----------|--------|------------|
| `environment` | tfvars file | `environment = "dev"` |
| `location` | tfvars file | `location = "Canada Central"` |
| `aks_node_count` | tfvars file | `aks_node_count = 1` |
| `grafana_azure_ad_client_id` | Environment var or secrets file | `export TF_VAR_grafana_azure_ad_client_id="..."` |
| `destinations_prometheus_url` | Grafana Cloud secrets file | See `GRAFANA_CLOUD_SETUP.md` |

### **Kubernetes Downward API** (Automatic - No Action Needed)

These are injected automatically by Kubernetes into pod environments:

| Variable | Source | Value Example |
|----------|--------|---------------|
| `NODE_NAME` | `spec.nodeName` | `aks-default-12345678-vmss000000` |
| `NAMESPACE` | `metadata.namespace` | `monitoring` |
| `POD_NAME` | `metadata.name` | `alloy-receiver-abc123` |

**How it works:**
```yaml
env:
  - name: NODE_NAME
    valueFrom:
      fieldRef:
        fieldPath: spec.nodeName  # ← Kubernetes fills this in automatically
```

### **Terraform Data Sources** (Automatic)

| Variable | Source | How It Works |
|----------|--------|--------------|
| `CLUSTER_NAME` | `azurerm_kubernetes_cluster.aks.name` | Set in `graphana-k8s-monitoring.tf` |
| `tenant_id` | `data.azurerm_client_config.current.tenant_id` | Auto-detected from Azure |

---

## 🔒 Secrets Management

### **What Should NEVER Be Committed:**

❌ **Variables.tf had these (NOW REMOVED):**
```hcl
default = "glc_eyJvIjoiMTU4MDk5MSIs..."  # API keys exposed!
```

✅ **Correct Approach:**
```hcl
variable "destinations_prometheus_password" {
  type      = string
  default   = ""  # No default!
  sensitive = true
}
```

### **Where to Store Secrets:**

**Development:**
```bash
# Option 1: Environment variables
export TF_VAR_destinations_prometheus_password="your-api-key"

# Option 2: Local secrets file (gitignored)
# Create infra/dev/grafana-cloud-secrets.tfvars
```

**CI/CD Pipeline:**
```
Azure DevOps → Pipeline → Variables → Add:
  - TF_VAR_destinations_prometheus_password (mark as secret)
  - TF_VAR_destinations_loki_password (mark as secret)
  - etc.
```

---

## 📊 Summary: Complete Deployment Flow

### **Infrastructure Deployment** (Rare - Only when infrastructure changes)

```bash
# LOCAL DEVELOPMENT:
cd infra
terraform init -backend-config="dev/backend.conf"
terraform apply -var-file="dev/dev.tfvars"

# USING PIPELINE ARTIFACTS:
# 1. Push to Git → Pipeline creates plan
# 2. Download tfplan-dev artifact
# 3. Restore lock file
# 4. terraform apply <artifact-path>/tfplan-dev
```

### **Application Deployment** (Frequent - Multiple times per day)

```bash
# ALWAYS USE THIS:
cd charts
./deploy.sh dev <image-tag>

# The script:
#   ✓ Reads Terraform outputs automatically
#   ✓ Gets cluster name, ACR URL, KeyVault name
#   ✓ Connects to AKS
#   ✓ Deploys via Helm
#   ✓ No manual configuration needed!
```

---

## 🎓 For Teaching: Simplified Explanation

**Tell students:**

1. **Terraform** = Build the infrastructure (run once)
   - Creates Azure resources
   - Installs monitoring tools
   - Takes ~20 minutes

2. **deploy.sh** = Deploy your application (run many times)
   - Reads what Terraform created
   - Deploys your code
   - Takes ~2 minutes

3. **Variables** from three sources:
   - **You provide**: Environment, location, credentials (via tfvars or env vars)
   - **Terraform provides**: Cluster name, resource names (from Terraform state)
   - **Kubernetes provides**: Pod name, node name, namespace (runtime info)

**Key Insight:** You never manually specify `NODE_NAME` or `NAMESPACE` - Kubernetes knows these values and injects them automatically into your pods!

---

## ✅ Quick Reference

| Action | Command |
|--------|---------|
| **Deploy infrastructure** | `cd infra && terraform apply -var-file="dev/dev.tfvars"` |
| **Deploy application** | `cd charts && ./deploy.sh dev <tag>` |
| **Access Grafana (local)** | `./scripts/access-services.sh grafana` |
| **Access Grafana Cloud** | `https://YOUR-STACK.grafana.net` |
| **View pods** | `kubectl get pods -n default` |
| **View logs** | `kubectl logs -n default -l app=backend -f` |
| **View Terraform outputs** | `cd infra && terraform output` |
| **Update infrastructure** | Edit Terraform files → Push → Download artifact → Apply |
| **Scale application** | Edit values.yaml → `./deploy.sh dev <tag>` |

---

## 🎉 Success!

You now have:
- ✅ Infrastructure managed by Terraform
- ✅ Cluster tools (Prometheus, Grafana, Nginx) auto-installed
- ✅ Optional Grafana Cloud integration
- ✅ Optional Azure AD authentication
- ✅ Simple deployment script
- ✅ Full monitoring and observability
- ✅ Secrets properly managed (not committed to Git)

Happy deploying! 🚀

