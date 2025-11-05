# Grafana Microsoft Entra ID (Azure AD) Setup Guide

This guide walks you through setting up Microsoft Entra ID authentication for Grafana.

## Prerequisites

- Azure AD tenant access
- Permission to create App Registrations
- Terraform already initialized

## Step 1: Create Azure AD App Registration

### Option A: Using Azure Portal (Easiest for Students)

1. **Go to Azure Portal** → **Azure Active Directory** → **App registrations**

2. **Click "New registration"**
   - Name: `Grafana-MCDA-Dev` (or appropriate name for your environment)
   - Supported account types: **Accounts in this organizational directory only**
   - Redirect URI: 
     - Platform: **Web**
     - URL: `http://localhost:3000/login/azuread` (for local access)
   - Click **Register**

3. **Note the Application (client) ID**
   - Copy this value - you'll need it for `grafana_azure_ad_client_id`

4. **Note the Directory (tenant) ID**
   - This should match your Terraform tenant ID

5. **Create a Client Secret**
   - Go to **Certificates & secrets** → **Client secrets**
   - Click **New client secret**
   - Description: `Grafana Auth Secret`
   - Expires: Choose appropriate duration (6 months, 12 months, or 24 months)
   - Click **Add**
   - **IMPORTANT**: Copy the secret **Value** immediately (you won't be able to see it again)
   - This is your `grafana_azure_ad_client_secret`

6. **Configure API Permissions**
   - Go to **API permissions**
   - Click **Add a permission** → **Microsoft Graph** → **Delegated permissions**
   - Add these permissions:
     - `openid`
     - `email`
     - `profile`
   - Click **Add permissions**
   - Click **Grant admin consent** (if you have admin rights)

7. **Optional: Configure App Roles** (for role-based access)
   - Go to **App roles** → **Create app role**
   - Display name: `Grafana Admin`
   - Allowed member types: **Users/Groups**
   - Value: `Admin`
   - Description: `Grafana Administrators`
   - Click **Apply**
   - Repeat for `Editor` and `Viewer` roles

### Option B: Using Azure CLI

```bash
# Login to Azure
az login

# Create App Registration
APP_NAME="Grafana-MCDA-Dev"
az ad app create \
  --display-name "$APP_NAME" \
  --sign-in-audience AzureADMyOrg \
  --web-redirect-uris "http://localhost:3000/login/azuread"

# Get the Application ID
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)
echo "Application (Client) ID: $APP_ID"

# Create Client Secret
SECRET=$(az ad app credential reset --id $APP_ID --query password -o tsv)
echo "Client Secret: $SECRET"
echo "SAVE THIS SECRET - YOU WON'T SEE IT AGAIN!"

# Add Microsoft Graph permissions
az ad app permission add \
  --id $APP_ID \
  --api 00000003-0000-0000-c000-000000000000 \
  --api-permissions \
    e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope \
    64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0=Scope \
    14dad69e-099b-42c9-810b-d002981feec1=Scope

# Grant admin consent (requires admin)
az ad app permission admin-consent --id $APP_ID
```

## Step 2: Store Secrets Securely

### Option A: Using Environment Variables (Development)

```bash
export TF_VAR_grafana_azure_ad_client_id="your-client-id-here"
export TF_VAR_grafana_azure_ad_client_secret="your-client-secret-here"
```

### Option B: Using Azure KeyVault (Recommended for Production)

```bash
# Store in KeyVault
az keyvault secret set \
  --vault-name mcda-dev-kv \
  --name grafana-azure-ad-client-id \
  --value "your-client-id-here"

az keyvault secret set \
  --vault-name mcda-dev-kv \
  --name grafana-azure-ad-client-secret \
  --value "your-client-secret-here"

# Retrieve when needed
CLIENT_ID=$(az keyvault secret show --vault-name mcda-dev-kv --name grafana-azure-ad-client-id --query value -o tsv)
CLIENT_SECRET=$(az keyvault secret show --vault-name mcda-dev-kv --name grafana-azure-ad-client-secret --query value -o tsv)
```

### Option C: Using .tfvars file (Not Recommended - Don't Commit!)

Create `infra/dev/secrets.tfvars` (add to .gitignore):

```hcl
grafana_azure_ad_client_id     = "your-client-id-here"
grafana_azure_ad_client_secret = "your-client-secret-here"
```

Then apply with:
```bash
terraform apply \
  -var-file="dev/dev.tfvars" \
  -var-file="dev/secrets.tfvars"
```

## Step 3: Update Terraform Configuration

### For Development Environment

Edit `infra/dev/dev.tfvars` to include (or pass via environment variables):

```hcl
# Add these lines (or use environment variables)
# grafana_azure_ad_client_id     = "your-client-id"
# grafana_azure_ad_client_secret = "your-client-secret"

# Note: Better to use environment variables or KeyVault for secrets
```

## Step 4: Deploy Infrastructure

```bash
cd infra

# Option 1: Using environment variables (recommended)
export TF_VAR_grafana_azure_ad_client_id="your-client-id"
export TF_VAR_grafana_azure_ad_client_secret="your-secret"
terraform apply -var-file="dev/dev.tfvars"

# Option 2: Using separate secrets file
terraform apply \
  -var-file="dev/dev.tfvars" \
  -var-file="dev/secrets.tfvars"

# Option 3: Interactive prompt
terraform apply -var-file="dev/dev.tfvars"
# Terraform will prompt for the variables
```

## Step 5: Access Grafana

```bash
# Port-forward to Grafana
./scripts/access-services.sh grafana

# Open browser to: http://localhost:3000
```

You should now see a **"Sign in with Microsoft Entra ID"** button!

## Step 6: Assign Users/Groups

### Via Azure Portal

1. Go to **Azure AD** → **Enterprise applications**
2. Find your app: `Grafana-MCDA-Dev`
3. Go to **Users and groups** → **Add user/group**
4. Select users/groups
5. Assign roles (Admin, Editor, or Viewer)

### Via Azure CLI

```bash
# Get user object ID
USER_EMAIL="student@yourdomain.com"
USER_ID=$(az ad user show --id $USER_EMAIL --query id -o tsv)

# Get app role ID for Admin
APP_ID="your-app-id"
ROLE_ID=$(az ad app show --id $APP_ID --query "appRoles[?value=='Admin'].id" -o tsv)

# Assign user to app with role
az ad app owner add --id $APP_ID --owner-object-id $USER_ID
```

## Troubleshooting

### Issue: "Sign in with Microsoft Entra ID" button not showing

**Solution:**
- Check Grafana logs: `kubectl logs -n monitoring <grafana-pod>`
- Verify client ID and secret are correct
- Ensure redirect URI matches exactly

### Issue: Login redirects but fails

**Solution:**
- Check redirect URI in Azure AD app registration
- Verify it matches: `http://localhost:3000/login/azuread`
- Check tenant ID is correct
- Verify API permissions are granted

### Issue: User logs in but has no access

**Solution:**
- Check user is assigned to the app in Azure AD
- Verify app roles are configured
- Check Grafana logs for role mapping issues

## Configuration for Production

For production, update the `root_url` in `cluster-tools.tf`:

```hcl
server = {
  root_url = "https://grafana.yourdomain.com"
}
```

And update the redirect URI in Azure AD:
- Add: `https://grafana.yourdomain.com/login/azuread`

## Role Mapping

Users will be assigned Grafana roles based on Azure AD app roles:

| Azure AD App Role | Grafana Role | Permissions |
|-------------------|--------------|-------------|
| Admin | Admin | Full access, can manage users and settings |
| Editor | Editor | Can edit dashboards and queries |
| Viewer | Viewer | Read-only access |
| (none) | Viewer | Default role if no app role assigned |

## Security Best Practices

1. ✅ **Never commit client secrets** to Git
2. ✅ **Use KeyVault** for production secrets
3. ✅ **Rotate secrets** regularly (every 6-12 months)
4. ✅ **Use specific redirect URIs** (not wildcards)
5. ✅ **Grant admin consent** for required permissions
6. ✅ **Assign users explicitly** (don't allow sign-up for production)
7. ✅ **Use HTTPS** for production (update root_url)
8. ✅ **Monitor** login attempts and failed authentications

## For Teaching

This setup demonstrates several important concepts:

1. **OAuth 2.0 / OpenID Connect** - Industry standard authentication
2. **Identity Provider Integration** - Using Azure AD as IdP
3. **Role-Based Access Control** - Mapping enterprise roles to app permissions
4. **Secret Management** - Proper handling of credentials
5. **Multi-tenant Architecture** - Enterprise authentication patterns

Students should understand:
- How OAuth 2.0 flows work
- The importance of proper secret management
- How role-based access control enhances security
- Why Single Sign-On (SSO) is valuable in enterprises

