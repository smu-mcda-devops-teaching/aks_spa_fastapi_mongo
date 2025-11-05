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

print_info "Initializing Terraform..."
terraform init -backend-config="${ENVIRONMENT}/backend.conf" > /dev/null 2>&1

# Extract Terraform outputs
print_info "Extracting infrastructure details..."

ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server 2>/dev/null)
AKS_NAME=$(terraform output -raw aks_cluster_name 2>/dev/null)
RESOURCE_GROUP=$(terraform output -raw resource_group_name 2>/dev/null)
KEY_VAULT_NAME=$(terraform output -raw key_vault_name 2>/dev/null)
TENANT_ID=$(terraform output -raw tenant_id 2>/dev/null)

# Validate outputs
if [ -z "$ACR_LOGIN_SERVER" ] || [ -z "$AKS_NAME" ] || [ -z "$RESOURCE_GROUP" ] || [ -z "$KEY_VAULT_NAME" ] || [ -z "$TENANT_ID" ]; then
    print_error "Failed to retrieve Terraform outputs. Make sure infrastructure is deployed."
    exit 1
fi

print_success "Retrieved infrastructure details:"
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
print_info "Deploying application via Helm..."
print_info "Release name: mcda-app"
print_info "Namespace: default"

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
    --set frontend.image.repository="${ACR_LOGIN_SERVER}/frontend" \
    --set frontend.image.tag="${IMAGE_TAG}" \
    --wait \
    --timeout 5m

print_success "Deployment completed successfully!"

# Show deployment status
print_info "Checking deployment status..."
echo ""
echo "Pods:"
kubectl get pods -n default -l "app in (backend,frontend)" --sort-by=.metadata.creationTimestamp

echo ""
echo "Services:"
kubectl get services -n default -l "app in (backend,frontend)"

echo ""
echo "Ingress:"
kubectl get ingress -n default 2>/dev/null || print_warning "No ingress found"

echo ""
print_success "Deployment to ${ENVIRONMENT} environment complete!"
print_info "Image tag deployed: ${IMAGE_TAG}"

# Optional: Show application URLs
echo ""
print_info "To check application logs, run:"
echo "  kubectl logs -n default -l app=backend --tail=50"
echo "  kubectl logs -n default -l app=frontend --tail=50"

echo ""
print_info "To port-forward for local testing:"
echo "  kubectl port-forward -n default svc/backend 8000:8000"
echo "  kubectl port-forward -n default svc/frontend 8080:80"

