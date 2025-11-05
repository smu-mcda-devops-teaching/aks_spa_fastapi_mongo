#!/bin/bash
################################################################################
# Deployment Script for MCDA Application to AKS
# 
# This script deploys the application to AKS using Helm charts with dynamic
# values from Terraform outputs.
#
# Usage:
#   ./deploy.sh <environment> [image_tag]
#
# Arguments:
#   environment - Target environment: dev, stage, or prod (required)
#   image_tag   - Docker image tag to deploy (optional, defaults to 'latest')
#
# Examples:
#   ./deploy.sh dev
#   ./deploy.sh prod v1.0.0
#   ./deploy.sh stage $(git rev-parse --short HEAD)
#
# Prerequisites:
#   - Azure CLI installed and authenticated (az login)
#   - Helm 3.x installed
#   - kubectl installed
#   - Terraform state initialized for the target environment
################################################################################

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ ${1}${NC}"
}

print_success() {
    echo -e "${GREEN}✓ ${1}${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ ${1}${NC}"
}

print_error() {
    echo -e "${RED}✗ ${1}${NC}"
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 <environment> [image_tag]

Arguments:
  environment    Target environment: dev, stage, or prod (required)
  image_tag      Docker image tag to deploy (optional, defaults to 'latest')

Examples:
  $0 dev
  $0 prod v1.0.0
  $0 stage \$(git rev-parse --short HEAD)

Prerequisites:
  - Azure CLI installed and authenticated
  - Helm 3.x installed
  - kubectl installed
  - Terraform initialized for target environment

EOF
    exit 1
}

# Check if environment argument is provided
if [ -z "$1" ]; then
    print_error "Environment argument is required"
    usage
fi

ENVIRONMENT=$1
IMAGE_TAG=${2:-latest}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|stage|prod)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT"
    print_info "Valid environments: dev, stage, prod"
    exit 1
fi

# Check prerequisites
print_info "Checking prerequisites..."

if ! command -v az &> /dev/null; then
    print_error "Azure CLI not found. Please install it: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

if ! command -v helm &> /dev/null; then
    print_error "Helm not found. Please install it: https://helm.sh/docs/intro/install/"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl not found. Please install it: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    print_error "Terraform not found. Please install it: https://www.terraform.io/downloads"
    exit 1
fi

print_success "All prerequisites met"

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INFRA_DIR="$SCRIPT_DIR/../infra"

print_info "Deploying to environment: ${ENVIRONMENT}"
print_info "Image tag: ${IMAGE_TAG}"

# Navigate to infra directory and get Terraform outputs
print_info "Retrieving Terraform outputs..."
cd "$INFRA_DIR"

# Initialize Terraform with the correct backend config
if [ ! -f "${ENVIRONMENT}/backend.conf" ]; then
    print_error "Backend config not found: ${ENVIRONMENT}/backend.conf"
    exit 1
fi

# Check for lock file to ensure provider consistency
print_info "Checking Terraform lock file..."
if [ -f ".terraform.lock.hcl" ]; then
    print_success "Lock file found - will use existing provider versions"
    LOCK_FILE_HASH=$(sha256sum .terraform.lock.hcl 2>/dev/null | awk '{print $1}' || md5 .terraform.lock.hcl 2>/dev/null | awk '{print $4}')
    echo "  Lock file hash: ${LOCK_FILE_HASH:0:16}..."
else
    print_warning "No lock file found - Terraform will download latest compatible providers"
    print_warning "For consistency, consider running 'terraform init' once and committing .terraform.lock.hcl"
fi

print_info "Initializing Terraform..."
terraform init -backend-config="${ENVIRONMENT}/backend.conf" > /dev/null 2>&1

# If lock file was just created, show it
if [ ! -f ".terraform.lock.hcl" ]; then
    print_error "Terraform init failed to create lock file"
    exit 1
fi

# Verify Terraform version and providers
print_info "Verifying Terraform configuration..."
TERRAFORM_VERSION=$(terraform version -json | grep -o '"terraform_version":"[^"]*' | cut -d'"' -f4)
echo "  Terraform version: $TERRAFORM_VERSION"

# Extract Terraform outputs
print_info "Extracting infrastructure details..."

ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server 2>/dev/null)
if [ $? -ne 0 ]; then
    print_error "Failed to read 'acr_login_server' output. Ensure infrastructure is deployed."
    exit 1
fi

AKS_NAME=$(terraform output -raw aks_cluster_name 2>/dev/null)
if [ $? -ne 0 ]; then
    print_error "Failed to read 'aks_cluster_name' output. Ensure infrastructure is deployed."
    exit 1
fi

RESOURCE_GROUP=$(terraform output -raw resource_group_name 2>/dev/null)
KEY_VAULT_NAME=$(terraform output -raw key_vault_name 2>/dev/null)
TENANT_ID=$(terraform output -raw tenant_id 2>/dev/null)

# Validate all outputs were retrieved
if [ -z "$ACR_LOGIN_SERVER" ] || [ -z "$AKS_NAME" ] || [ -z "$RESOURCE_GROUP" ] || [ -z "$KEY_VAULT_NAME" ] || [ -z "$TENANT_ID" ]; then
    print_error "Failed to retrieve all required Terraform outputs."
    print_error "Make sure infrastructure is deployed to the ${ENVIRONMENT} environment."
    echo ""
    echo "Available outputs:"
    terraform output 2>&1
    exit 1
fi

print_success "Retrieved infrastructure details:"
echo "  Environment:   $ENVIRONMENT"
echo "  ACR:           $ACR_LOGIN_SERVER"
echo "  AKS Cluster:   $AKS_NAME"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Key Vault:     $KEY_VAULT_NAME"
echo "  Tenant ID:     $TENANT_ID"

# Get AKS credentials
print_info "Getting AKS credentials..."
az aks get-credentials \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_NAME" \
    --overwrite-existing > /dev/null 2>&1

print_success "Connected to AKS cluster"

# Verify cluster connectivity
print_info "Verifying cluster connectivity..."
if ! kubectl cluster-info > /dev/null 2>&1; then
    print_error "Failed to connect to Kubernetes cluster"
    exit 1
fi
print_success "Cluster is reachable"

# Navigate to charts directory
cd "$SCRIPT_DIR"

# Check if values file exists for environment
VALUES_FILE="values.${ENVIRONMENT}.yaml"
if [ ! -f "$VALUES_FILE" ]; then
    print_error "Values file not found: $VALUES_FILE"
    exit 1
fi

print_info "Using values file: $VALUES_FILE"

# Update Helm dependencies
print_info "Updating Helm dependencies..."
helm dependency update > /dev/null 2>&1 || true
print_success "Dependencies updated"

# Deploy with Helm
echo ""
echo "=========================================="
print_info "Deploying application via Helm..."
echo "=========================================="
echo "  Release name: mcda-app"
echo "  Namespace:    default"
echo "  Environment:  $ENVIRONMENT"
echo "  Image tag:    $IMAGE_TAG"
echo "  Values file:  $VALUES_FILE"
echo "=========================================="
echo ""

# Show what will be deployed
print_info "Configuration:"
echo "  Global image repository: ${ACR_LOGIN_SERVER}"
echo "  Backend image: ${ACR_LOGIN_SERVER}/backend:${IMAGE_TAG}"
echo "  Frontend image: ${ACR_LOGIN_SERVER}/frontend:${IMAGE_TAG}"
echo "  KeyVault: ${KEY_VAULT_NAME}"
echo ""

helm upgrade --install mcda-app . \
    --namespace default \
    --create-namespace \
    --values "$VALUES_FILE" \
    --set global.image.repository="${ACR_LOGIN_SERVER}" \
    --set global.image.tag="${IMAGE_TAG}" \
    --set global.keyVault.name="${KEY_VAULT_NAME}" \
    --set global.keyVault.tenantId="${TENANT_ID}" \
    --set backend.image.repository="${ACR_LOGIN_SERVER}/backend" \
    --set backend.image.tag="${IMAGE_TAG}" \
    --set backend.keyVault.name="${KEY_VAULT_NAME}" \
    --set backend.keyVault.tenantId="${TENANT_ID}" \
    --set frontend.image.repository="${ACR_LOGIN_SERVER}/frontend" \
    --set frontend.image.tag="${IMAGE_TAG}" \
    --wait \
    --timeout 5m

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    print_success "Deployment completed successfully!"
    echo "=========================================="
else
    print_error "Helm deployment failed!"
    exit 1
fi

# Show deployment status
print_info "Checking deployment status..."
echo ""
echo "==================== PODS ===================="
kubectl get pods -n default -l "app in (backend,frontend)" --sort-by=.metadata.creationTimestamp

echo ""
echo "================== SERVICES =================="
kubectl get services -n default -l "app in (backend,frontend)"

echo ""
echo "=================== INGRESS =================="
kubectl get ingress -n default 2>/dev/null || print_warning "No ingress resources found"

echo ""
echo "============== DEPLOYMENT DETAILS ============"
kubectl get deployments -n default -l "app in (backend,frontend)"

echo ""
echo "=========================================="
print_success "Deployment to ${ENVIRONMENT} environment complete!"
echo "=========================================="
echo "  Environment:  ${ENVIRONMENT}"
echo "  Release:      mcda-app"
echo "  Namespace:    default"
echo "  Image tag:    ${IMAGE_TAG}"
echo "  ACR:          ${ACR_LOGIN_SERVER}"
echo "  KeyVault:     ${KEY_VAULT_NAME}"
echo "=========================================="

# Wait for pods to be ready
echo ""
print_info "Waiting for pods to be ready..."
if kubectl wait --for=condition=ready pod -l "app in (backend,frontend)" -n default --timeout=120s 2>/dev/null; then
    print_success "All pods are ready!"
else
    print_warning "Some pods may still be starting. Check status with: kubectl get pods -n default"
fi

# Optional: Show application URLs and next steps
echo ""
echo "==================== NEXT STEPS ===================="
print_info "To check application logs:"
echo "  Backend:  kubectl logs -n default -l app=backend --tail=50 -f"
echo "  Frontend: kubectl logs -n default -l app=frontend --tail=50 -f"

echo ""
print_info "To port-forward for local testing:"
echo "  Backend:  kubectl port-forward -n default svc/backend 8000:8000"
echo "  Frontend: kubectl port-forward -n default svc/frontend 8080:80"

echo ""
print_info "To view all resources:"
echo "  kubectl get all -n default"

echo ""
print_info "To view Helm release:"
echo "  helm list -n default"
echo "  helm status mcda-app -n default"
echo "===================================================="

