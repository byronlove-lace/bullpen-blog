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
APP_NAME=$(jq -r '.appName.value' infra/params.json)
APP_SERVICE_PLAN_NAME=$(jq -r '.planName.value' infra/params.json)
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

# Check if Database exists
if az sql db show --name "$DATABASE_NAME" --resource-group "$RESOURCE_GROUP" --server "$SQL_SERVER_NAME" &>/dev/null; then
  echo "DB already exists. Skipping creation..."
  CREATE_DB=false
  DATABASE_ADMIN_PASSWORD=''
else
  echo "No SQL DB found, creating new DB..."
  CREATE_DB=true
  DATABASE_ADMIN_PASSWORD=$(openssl rand -base64 32)
  PROD_DB_URI="mssql+pyodbc://${DATABASE_ADMIN_USERNAME}:${DATABASE_ADMIN_PASSWORD}@${SQL_SERVER_NAME}.database.windows.net:1433/${DATABASE_NAME}?driver=ODBC+Driver+18+for+SQL+Server"
fi

# Check if App Service Plan exists
if az appservice plan show --name "$APP_SERVICE_PLAN_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
  echo "App Service Plan already exists. Skipping creation..."
  CREATE_ASP=false
else
  echo "No App Service Plan found. Creating now..."
  CREATE_ASP=true
fi

# Check if App exists
if az webapp show --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
  echo "App already exists. Skipping creation..."
  CREATE_APP=false
else
  echo "No App found. Creating app..."
  CREATE_APP=true
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
  createDatabase=$CREATE_DB \
  createAppServicePlan=$CREATE_ASP \
  createApp=$CREATE_APP

# Adding Secrets
if [ "$CREATE_KV" = true ]; then
  echo "Adding new Secret Key to secrets..."
  SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
  az keyvault secret set --vault-name "$KEYVAULT_NAME" --name "SecretKey" --value "$SECRET_KEY" &>/dev/null
fi

if [ "$CREATE_DB" = true ]; then
  echo "Adding new DB Admin password and DB URI to secrets..."
  az keyvault secret set --vault-name "$KEYVAULT_NAME" --name "ProdDatabaseAdminPassword" --value "$DATABASE_ADMIN_PASSWORD" &>/dev/null
  az keyvault secret set --vault-name "$KEYVAULT_NAME" --name "ProdDatabaseURI" --value "$PROD_DB_URI" &>/dev/null
fi
