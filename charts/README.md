# Helm Charts Deployment Guide

## Overview
This umbrella Helm chart deploys a full application stack to Azure Kubernetes Service (AKS), including:
- Frontend (React SPA)
- Backend (FastAPI with MongoDB)
- Ingress Controller

It also integrates with Azure Key Vault to securely manage secrets for Stripe and PayPal.

---

## Prerequisites
- AKS cluster with CSI Secrets Store Driver enabled
- Azure Key Vault with secrets:
  - STRIPE_SECRET_KEY
  - STRIPE_WEBHOOK_SECRET
  - PAYPAL_CLIENT_ID
  - PAYPAL_CLIENT_SECRET
- Azure Container Registry (ACR) with built images
- Helm installed locally

---

## 1. Backend Deployment
```bash
helm upgrade --install backend ./backend   --set image.repository=<ACR_LOGIN_SERVER>/backend   --set image.tag=latest   --set keyVault.name=mykeyvaultaks   --set keyVault.tenantId=<tenant-id>
```

Ensure the CSI driver is enabled:
```bash
az aks enable-addons --addons azure-keyvault-secrets-provider   --name myakscluster --resource-group aks-rg
```

---

## 2. Frontend Deployment
```bash
helm upgrade --install frontend ./frontend   --set image.repository=<ACR_LOGIN_SERVER>/frontend   --set image.tag=latest
```

---

## 3. Ingress Deployment
```bash
helm upgrade --install ingress ./ingress   --set host=myapp.example.com
```

This will route:
- `/` to frontend
- `/api` to backend

---

## Configuration Options
- `global.image.repository`: ACR login server
- `global.image.tag`: Image tag to deploy
- `global.keyVault.name`: Azure Key Vault name
- `global.keyVault.tenantId`: Azure AD tenant ID
- `ingress.host`: Domain name for ingress routing

---

## Notes
- Replace `<ACR_LOGIN_SERVER>` and `<tenant-id>` with actual values.
- Ensure secrets are correctly mounted in backend pod.
- Use HTTPS ingress with TLS for production.
- Ensure secrets are created in Key Vault:
```bash
az keyvault secret set --vault-name mykeyvaultaks --name STRIPE_SECRET_KEY --value "sk_test_..."
az keyvault secret set --vault-name mykeyvaultaks --name PAYPAL_CLIENT_ID --value "your-client-id"
az keyvault secret set --vault-name mykeyvaultaks --name PAYPAL_CLIENT_SECRET --value "your-client-secret"
```
- TLS and HTTPS ingress can be added via cert-manager.