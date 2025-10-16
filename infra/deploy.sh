#!/usr/bin/env bash
set -euo pipefail

# Optional: define deployment name
DEPLOYMENT_NAME="bullpen-blog-deployment"

# Dynamically retrieve current user's Azure AD objectId for Key Vault role assignment
OFFICER_PRINCIPAL_ID=$(az ad signed-in-user show --query id -o tsv)

RESOURCE_GROUP=$(jq -r '.resourceGroupName.value' infra/params.json)
KEYVAULT_NAME=$(jq -r '.keyVaultName.value' infra/params.json)
DATABASE_NAME=$(jq -r '.sqlDBName.value' infra/params.json)
SQL_SERVER_NAME=$(jq -r '.sqlServerName.value' infra/params.json)
DATABASE_ADMIN_USERNAME=$(jq -r '.sqlDBAdminUsername.value' infra/params.json)
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

if az sql db show --name "$DATABASE_NAME" --resource-group "$RESOURCE_GROUP" --server "$SQL_SERVER_NAME" &>/dev/null; then
  echo "DB already exists. Skipping creation..."
  CREATE_DB=false
  DATABASE_ADMIN_PASSWORD=''
else
  echo "No SQL DB found, generating new admin password and creating new DB..."
  CREATE_DB=true
  DATABASE_ADMIN_PASSWORD=$(openssl rand -base64 32)
  PROD_DB_URI="mssql+pyodbc://${DATABASE_ADMIN_USERNAME}:${DATABASE_ADMIN_PASSWORD}@${SQL_SERVER_NAME}.database.windows.net:1433/${DATABASE_NAME}?driver=ODBC+Driver+18+for+SQL+Server"

  az keyvault secret set --vault-name "$KEYVAULT_NAME" --name "ProdDatabaseAdminPassword" --value "$DATABASE_ADMIN_PASSWORD" &>/dev/null
  az keyvault secret set --vault-name "$KEYVAULT_NAME" --name "ProdDatabaseURI" --value "$PROD_DB_URI" &>/dev/null
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
  sqlDBAdminPassword="$DATABASE_ADMIN_PASSWORD" \
  createDatabase=$CREATE_DB
