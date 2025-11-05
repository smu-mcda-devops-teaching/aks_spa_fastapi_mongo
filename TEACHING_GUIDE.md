# Teaching Guide: Cloud-Native Application Deployment

## 🎓 Overview

This guide is designed to help students understand modern cloud-native application deployment using industry-standard tools and practices.

## 📚 Learning Objectives

By completing this project, students will learn:

1. **Infrastructure as Code** (Terraform)
2. **Container Orchestration** (Kubernetes/AKS)
3. **Monitoring & Observability** (Prometheus & Grafana)
4. **CI/CD Pipelines** (Azure DevOps)
5. **Cloud Services** (Azure - AKS, ACR, KeyVault, CosmosDB)
6. **Helm Package Management** (Kubernetes application packaging)

## 🏗️ Architecture Overview

```
┌───────────────────────────────────────────────────────────────┐
│ LAYER 1: Infrastructure (Terraform)                           │
│ ├─ AKS Cluster                                                │
│ ├─ Azure Container Registry (ACR)                             │
│ ├─ KeyVault (Secrets Management)                              │
│ ├─ CosmosDB (Database)                                        │
│ └─ Cluster Tools (Prometheus, Grafana, Nginx)                 │
└───────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌───────────────────────────────────────────────────────────────┐
│ LAYER 2: Applications (Kubernetes + Helm)                     │
│ ├─ Backend (FastAPI)                                          │
│ ├─ Frontend (React/SPA)                                       │
│ └─ Ingress (Nginx)                                            │
└───────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌───────────────────────────────────────────────────────────────┐
│ LAYER 3: Observability (Prometheus + Grafana)                 │
│ ├─ Metrics Collection                                         │
│ ├─ Dashboards                                                 │
│ └─ Alerting                                                   │
└───────────────────────────────────────────────────────────────┘
```

## 🚀 Setup Instructions for Students

### Prerequisites

Install these tools before starting:

```bash
# 1. Azure CLI
brew install azure-cli  # macOS
# or: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli

# 2. Terraform
brew install terraform  # macOS
# or: https://www.terraform.io/downloads

# 3. Kubectl
brew install kubectl  # macOS
# or: https://kubernetes.io/docs/tasks/tools/

# 4. Helm
brew install helm  # macOS
# or: https://helm.sh/docs/intro/install/
```

### Step 1: Deploy Infrastructure (30 minutes)

**What you're learning:** Infrastructure as Code, Cloud resource provisioning

```bash
# 1. Login to Azure
az login

# 2. Navigate to infrastructure directory
cd infra

# 3. Initialize Terraform
terraform init -backend-config="dev/backend.conf"

# 4. Review what will be created
terraform plan -var-file="dev/dev.tfvars"

# 5. Deploy infrastructure
terraform apply -var-file="dev/dev.tfvars"
```

**What gets created:**
- ✅ AKS Cluster (Kubernetes)
- ✅ Container Registry (for Docker images)
- ✅ KeyVault (for secrets)
- ✅ CosmosDB (MongoDB-compatible database)
- ✅ Prometheus + Grafana (Monitoring stack)
- ✅ Nginx Ingress (Traffic routing)
- ✅ CSI Secrets Driver (KeyVault integration)

**Time:** ~15-20 minutes for Azure to provision resources

### Step 2: Access Cluster Tools (5 minutes)

**What you're learning:** Kubernetes basics, port-forwarding

```bash
# Get AKS credentials
az aks get-credentials --resource-group mcda-dev-rg --name mcda-dev-aks

# Verify connection
kubectl get nodes

# View monitoring tools
kubectl get pods -n monitoring

# Access Grafana UI
cd ../scripts
./access-services.sh grafana

# Or access both Grafana and Prometheus
./access-services.sh all
```

**Open browser to:** http://localhost:3000

**Authentication Options:**
- **Default**: Username: `admin` / Password: `admin`
- **Microsoft Entra ID** (if configured): Click "Sign in with Microsoft Entra ID"
  - See `infra/GRAFANA_AZURE_AD_SETUP.md` for setup instructions
  - Uses your organizational Azure AD credentials
  - Role-based access control (Admin/Editor/Viewer)

### Step 3: Deploy Your Application (10 minutes)

**What you're learning:** Helm deployments, Kubernetes applications

```bash
# Navigate to charts directory
cd ../charts

# Deploy your application
./deploy.sh dev

# Watch pods start
kubectl get pods -w
```

**What just happened:**
1. Script retrieved infrastructure details from Terraform
2. Connected to your AKS cluster  
3. Deployed frontend and backend using Helm
4. Configured KeyVault integration
5. Set up ingress routing

**View deployment:**
```bash
kubectl get all -n default
```

### Step 4: Monitor Your Application (10 minutes)

**What you're learning:** Observability, metrics, dashboards

**Access Grafana dashboards:**
```bash
# If not already running
./scripts/access-services.sh grafana
```

**Explore pre-installed dashboards:**
1. Go to Dashboards → Browse
2. Open "Kubernetes / Compute Resources / Cluster"
3. Explore "Kubernetes / Compute Resources / Namespace (Pods)"
4. Check "Nginx Ingress Controller"

**Key Metrics to Observe:**
- CPU and Memory usage
- Pod count and status
- Network I/O
- Container restart count

### Step 5: Make a Code Change (20 minutes)

**What you're learning:** Update deployment workflow

```bash
# 1. Make a change to your application
vim ../backend/app/main.py

# Add a new endpoint:
@app.get("/hello")
def hello():
    return {"message": "Hello from updated app!"}

# 2. Build new Docker image
docker build -t <your-acr>.azurecr.io/backend:v2 ../backend

# 3. Push to ACR
az acr login --name <your-acr>
docker push <your-acr>.azurecr.io/backend:v2

# 4. Update deployment
cd charts
./deploy.sh dev v2

# 5. Verify the update
kubectl get pods  # Watch new pods roll out
kubectl logs <new-backend-pod>  # Check logs
```

## 🎯 Key Concepts Explained

### 1. Infrastructure as Code (IaC)

**Traditional way:**
- Click buttons in Azure Portal
- Manual configuration
- Hard to replicate
- No version control

**Our way (Terraform):**
```hcl
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "mcda-dev-aks"
  location            = "Canada Central"
  resource_group_name = azurerm_resource_group.rg.name
  ...
}
```

**Benefits:**
- ✅ Version controlled
- ✅ Repeatable
- ✅ Documented
- ✅ Reviewable (code reviews)

### 2. Helm Package Management

**Why Helm?**
- Templating for Kubernetes manifests
- Package multiple resources together
- Easy upgrades and rollbacks
- Manage configuration per environment

**Example:**
```yaml
# values.dev.yaml - Development configuration
backend:
  replicaCount: 1
  resources:
    requests:
      memory: "256Mi"

# values.prod.yaml - Production configuration  
backend:
  replicaCount: 3
  resources:
    requests:
      memory: "1Gi"
```

### 3. Monitoring with Prometheus + Grafana

**Prometheus:**
- Collects metrics every 15 seconds
- Stores time-series data
- Provides query language (PromQL)
- Scrapes metrics from applications

**Grafana:**
- Visualizes Prometheus metrics
- Pre-built dashboards
- Alerting capabilities
- Customizable views

**Example queries:**
```promql
# CPU usage
rate(container_cpu_usage_seconds_total[5m])

# Memory usage
container_memory_usage_bytes

# Pod restarts
kube_pod_container_status_restarts_total

# HTTP requests per second
rate(nginx_ingress_controller_requests[5m])
```

## 🧪 Experiments for Students

### Experiment 1: Scale Your Application

```bash
# Edit values file
vim charts/values.dev.yaml

# Change backend.replicaCount from 1 to 3
backend:
  replicaCount: 3

# Redeploy
./deploy.sh dev

# Watch scaling in Grafana
# - Go to Kubernetes Pods dashboard
# - Filter by namespace: default
# - Watch new pods appear
```

**Questions to explore:**
- How long does it take to scale?
- Can you see the new pods in Grafana?
- What happens to CPU/Memory metrics?

### Experiment 2: Simulate a Failure

```bash
# Delete a pod
kubectl delete pod <backend-pod-name>

# Watch Kubernetes recreate it
kubectl get pods -w

# Check in Grafana:
# - Pod restart count increases
# - Brief gap in metrics
# - Application continues running
```

**Questions to explore:**
- How long was the pod unavailable?
- Did the frontend continue working?
- Can you see the restart event in Grafana?

### Experiment 3: View Application Logs

```bash
# View logs from all backend pods
kubectl logs -l app=backend --tail=50 -f

# View logs from specific pod
kubectl logs <pod-name> -f

# View logs from previous pod instance (after crash)
kubectl logs <pod-name> --previous
```

**Questions to explore:**
- What information is in the logs?
- How can logs help debug issues?
- Can you correlate log events with Grafana metrics?

## 📊 Assessment Criteria

Students should be able to:

| Skill | Beginner | Intermediate | Advanced |
|-------|----------|--------------|----------|
| Deploy infra | Run commands | Explain each resource | Modify Terraform code |
| Use Helm | Deploy app | Update values files | Create custom charts |
| Monitor apps | View dashboards | Read metrics | Create custom dashboards |
| Debug issues | Read logs | Identify problems | Fix and deploy solutions |
| K8s concepts | Basic commands | Understand resources | Design architectures |

## 🔧 Troubleshooting Guide

### Problem: Terraform fails to apply

**Solution:**
```bash
# Check Azure credentials
az account show

# Verify backend state storage exists
az storage account show --name tfstatemcda2025

# Re-initialize
terraform init -backend-config="dev/backend.conf" -reconfigure
```

### Problem: Can't access Grafana

**Solution:**
```bash
# Check if Grafana is running
kubectl get pods -n monitoring

# Restart port-forward
./scripts/access-services.sh grafana

# Reset Grafana password if needed
kubectl exec -it -n monitoring <grafana-pod> -- grafana-cli admin reset-admin-password newpassword
```

### Problem: Application won't deploy

**Solution:**
```bash
# Check Helm releases
helm list -n default

# View deployment status
kubectl get deployments -n default

# Check pod status and events
kubectl describe pod <pod-name>

# View logs
kubectl logs <pod-name>

# Delete and redeploy
helm uninstall mcda-app -n default
./deploy.sh dev
```

### Problem: Images won't pull from ACR

**Solution:**
```bash
# Verify ACR credentials
az acr login --name <your-acr>

# Check AKS has pull permissions
kubectl get secrets

# Manually verify image exists
az acr repository list --name <your-acr>
az acr repository show-tags --name <your-acr> --repository backend
```

## 📝 Assignment Ideas

### Assignment 1: Add Monitoring to Your App
- Expose metrics endpoint in backend
- Configure Prometheus to scrape it
- Create custom Grafana dashboard
- Set up alerts for high error rates

### Assignment 2: Implement Rolling Updates
- Deploy version 1 of backend
- Build and push version 2
- Update deployment
- Observe zero-downtime deployment
- Document the process

### Assignment 3: Multi-Environment Deployment
- Deploy to dev environment
- Test your changes
- Deploy same version to stage
- Compare configurations
- Document differences

## 🎓 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Helm Documentation](https://helm.sh/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## 💡 Best Practices Demonstrated

1. **Never commit secrets** - Use KeyVault
2. **Automate deployments** - IaC + scripts
3. **Monitor everything** - Prometheus + Grafana
4. **Version control** - Git for code and config
5. **Use namespaces** - Logical separation
6. **Tag images properly** - Never use `latest` in production
7. **Resource limits** - Set CPU/memory requests and limits
8. **Health checks** - Liveness and readiness probes

---

## 🎉 Success Criteria

Students have successfully completed this module when they can:

- ✅ Deploy infrastructure from code
- ✅ Deploy applications using Helm
- ✅ Access and navigate Grafana dashboards
- ✅ Read and interpret Prometheus metrics
- ✅ Make code changes and redeploy
- ✅ Debug application issues using logs and metrics
- ✅ Scale applications up and down
- ✅ Explain the deployment workflow

Good luck and happy learning! 🚀
