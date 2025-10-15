#!/usr/bin/env bash
set -euo pipefail

# Optional: define deployment name
DEPLOYMENT_NAME="bullpen-blog-deployment"

# Dynamically retrieve current user's Azure AD objectId for Key Vault role assignment
OFFICER_PRINCIPAL_ID=$(az ad signed-in-user show --query id -o tsv)

RESOURCE_GROUP=$(jq -r '.resourceGroupName.value' infra/params.json)
KEYVAULT_NAME=$(jq -r '.keyVaultName.value' infra/params.json)
DATABASE_NAME=$(jq -r '.databaseName.value' infra/params.json)
LOCATION=$(jq -r '.resourceGroupLocation.value' infra/params.json)
KEYVAULT_ID=''

# Check if Key Vault exists
if az keyvault show --name "$KEYVAULT_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
  echo "Key Vault exists, skipping creation"
  CREATE_KV=false
  KEYVAULT_ID=$(az keyvault show --name "$KEYVAULT_NAME" --resource-group "$RESOURCE_GROUP" --query "id" -o tsv)
else
  CREATE_KV=true
fi

if az sql db show --name "$DATABASE_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
  echo "DB already exists. Skipping creation..."
  CREATE_DB=false
  SQL_ADMIN_PASSWORD=''
else
  echo "No SQL DB found, generating new admin password and creating new DB..."
  CREATE_DB=true
  SQL_ADMIN_PASSWORD=$(openssl rand -base64 32)
  az keyvault secret set --vault-name "$KEYVAULT_NAME" --name "SqlAdminPassword" --value "$SQL_ADMIN_PASSWORD" &>/dev/null
fi

# Launch deployment
az deployment sub create \
  --name "$DEPLOYMENT_NAME" \
  --location "$LOCATION" \
  --template-file infra/main.bicep \
  --parameters @infra/params.json \
  officerPrincipalId="$OFFICER_PRINCIPAL_ID" \
  createKeyVault=$CREATE_KV \
  existingKeyVaultId="$KEYVAULT_ID" \
  sqlDBAdminPassword="$SQL_ADMIN_PASSWORD" \
  createDatabase=$CREATE_DB
