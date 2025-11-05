# Quick Start Guide

Get up and running in 30 minutes!

## 🚀 Prerequisites

```bash
# Install required tools
brew install azure-cli terraform kubectl helm docker

# Verify installations
az --version
terraform --version
kubectl version --client
helm version
```

## 📋 3-Step Deployment

### **Step 1: Deploy Infrastructure** (~20 minutes)

```bash
# Login to Azure
az login

# Navigate to infrastructure
cd infra

# Initialize Terraform
terraform init -backend-config="dev/backend.conf"

# Deploy everything
terraform apply -var-file="dev/dev.tfvars"
```

**What you get:**
- ✅ Kubernetes cluster (AKS)
- ✅ Container registry (ACR)
- ✅ Secrets vault (KeyVault)
- ✅ Database (CosmosDB)
- ✅ Monitoring (Prometheus + Grafana)
- ✅ Ingress controller (Nginx)

### **Step 2: Build & Push Images** (~5 minutes)

```bash
# Get ACR name
ACR_NAME=$(terraform output -raw acr_name)

# Login to ACR
az acr login --name $ACR_NAME

# Build and push backend
cd ../backend
docker build -t ${ACR_NAME}.azurecr.io/backend:v1 .
docker push ${ACR_NAME}.azurecr.io/backend:v1

# Build and push frontend (if applicable)
cd ../frontend
docker build -t ${ACR_NAME}.azurecr.io/frontend:v1 .
docker push ${ACR_NAME}.azurecr.io/frontend:v1
```

### **Step 3: Deploy Application** (~2 minutes)

```bash
# Deploy using the script
cd ../charts
./deploy.sh dev v1

# Wait for pods to be ready
kubectl get pods -w
```

---

## 🎉 Access Your Services

### **Application**

```bash
# Port-forward to backend
kubectl port-forward -n default svc/backend 8000:8000

# Test API
curl http://localhost:8000/docs
```

### **Grafana Dashboard**

```bash
# Start port-forward
cd ../scripts
./access-services.sh grafana

# Open browser
# http://localhost:3000
# Login: admin / admin
```

### **Prometheus**

```bash
# Access Prometheus
./access-services.sh prometheus

# Open browser
# http://localhost:9090
```

---

## 📚 Next Steps

### **For Learning:**
- Read `TEACHING_GUIDE.md` for detailed learning objectives
- Explore Grafana dashboards
- Try scaling your application
- Make code changes and redeploy

### **For Production:**
- Set up Azure AD authentication (see `GRAFANA_AZURE_AD_SETUP.md`)
- Configure Grafana Cloud (see `GRAFANA_CLOUD_SETUP.md`)
- Review deployment workflow (see `DEPLOYMENT_WORKFLOW.md`)
- Set up CI/CD pipelines in Azure DevOps

---

## 🔧 Troubleshooting

### **Terraform fails to initialize**
```bash
# Check Azure credentials
az account show

# Re-initialize
terraform init -backend-config="dev/backend.conf" -reconfigure
```

### **Can't push images to ACR**
```bash
# Re-login
ACR_NAME=$(cd infra && terraform output -raw acr_name)
az acr login --name $ACR_NAME

# Verify repository name
docker images | grep ${ACR_NAME}
```

### **Deploy script fails**
```bash
# Ensure infrastructure is deployed
cd infra
terraform output  # Should show all values

# Get AKS credentials
RESOURCE_GROUP=$(terraform output -raw resource_group_name)
AKS_NAME=$(terraform output -raw aks_cluster_name)
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME
```

### **Grafana won't load**
```bash
# Check if Grafana pod is running
kubectl get pods -n monitoring | grep grafana

# Check logs
kubectl logs -n monitoring <grafana-pod-name>

# Restart port-forward
./scripts/access-services.sh grafana
```

---

## 📖 Documentation Index

| Document | Purpose |
|----------|---------|
| `QUICKSTART.md` | This file - Get started in 30 minutes |
| `TEACHING_GUIDE.md` | Complete guide for students with exercises |
| `DEPLOYMENT_WORKFLOW.md` | Detailed deployment process with pipelines |
| `SETUP_SUMMARY.md` | Overview of all files and configuration |
| `infra/GRAFANA_AZURE_AD_SETUP.md` | Enterprise SSO setup |
| `infra/GRAFANA_CLOUD_SETUP.md` | Managed monitoring setup |
| `infra/README.md` | Infrastructure-specific documentation |
| `charts/README.md` | Helm charts documentation |

---

## 🎯 Common Commands

```bash
# Deploy infrastructure
cd infra && terraform apply -var-file="dev/dev.tfvars"

# Deploy application
cd charts && ./deploy.sh dev <tag>

# Access Grafana
./scripts/access-services.sh grafana

# View pods
kubectl get pods -A

# View logs
kubectl logs -n default -l app=backend -f

# Scale backend
kubectl scale deployment backend -n default --replicas=3

# View Helm releases
helm list -A

# Update application
./charts/deploy.sh dev v2

# Destroy everything
cd infra && terraform destroy -var-file="dev/dev.tfvars"
```

---

## ✅ Success Criteria

You know it's working when:

- ✅ `terraform output` shows all infrastructure details
- ✅ `kubectl get nodes` shows your AKS nodes
- ✅ `kubectl get pods -A` shows all pods running
- ✅ Grafana opens at http://localhost:3000
- ✅ Backend API accessible at http://localhost:8000/docs
- ✅ You see metrics in Grafana dashboards

Happy deploying! 🚀

Need help? Check the other documentation files or run commands with `-h` or `--help` flags.

