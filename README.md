# AKS SPA + FastAPI + MongoDB Deployment

## Overview
This project deploys a React SPA frontend and FastAPI backend connected to MongoDB on Azure Kubernetes Service (AKS). It uses:
- **Terraform** for infrastructure provisioning
- **Helm** for Kubernetes deployments
- **Azure Key Vault** for secret management
- **Azure DevOps** for CI/CD pipelines

## Prerequisites
- Azure CLI
- Terraform
- Helm
- Docker
- Azure DevOps account
- kubectl CLI

## Steps
### 1. Provision Infrastructure
```bash
cd infra
terraform init
terraform apply
```
### 2. Build and Push Docker Images
```bash
docker build -t <ACR_LOGIN_SERVER>/frontend:latest ./frontend
docker build -t <ACR_LOGIN_SERVER>/backend:latest ./backend
az acr login --name <acr_name>
docker push <ACR_LOGIN_SERVER>/frontend:latest
docker push <ACR_LOGIN_SERVER>/backend:latest
```
### 3. Deploy with Helm
```bash
helm upgrade --install frontend ./charts/frontend --set image.repository=<ACR_LOGIN_SERVER>/frontend --set image.tag=latest
helm upgrade --install backend ./charts/backend --set image.repository=<ACR_LOGIN_SERVER>/backend --set image.tag=latest
helm upgrade --install ingress ./charts/ingress
```
### 4. Enable Key Vault CSI Driver
```bash
az aks enable-addons --addons azure-keyvault-secrets-provider --name myakscluster --resource-group aks-rg
```
### 5. Configure Azure DevOps Pipelines
Use `azure-pipelines-build.yml` and `azure-pipelines-deploy.yml`.

## Best Practices
- Use Cosmos DB with Mongo API for managed MongoDB.
- Enable HTTPS ingress with TLS certificates.
- Configure Horizontal Pod Autoscaler.
- Use Azure Monitor for observability.
