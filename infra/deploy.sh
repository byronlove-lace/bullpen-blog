#!/usr/bin/env bash
set -euo pipefail

# Optional: define deployment name
DEPLOYMENT_NAME="bullpen-blog-deployment"

# Dynamically retrieve current user's Azure AD objectId for Key Vault role assignment
OFFICER_PRINCIPAL_ID=$(az ad signed-in-user show --query id -o tsv)

RESOURCE_GROUP=$(jq -r '.resourceGroupName.value' infra/params.json)
KEYVAULT_NAME=$(jq -r '.keyVaultName.value' infra/params.json)
DATABASE_NAME=$(jq -r '.sqlDBName.value' infra/params.json)
DATABASE_ADMIN_PASSWORD=''
SQL_SERVER_NAME=$(jq -r '.sqlServerName.value' infra/params.json)
APP_NAME=$(jq -r '.appName.value' infra/params.json)
APP_SERVICE_PLAN_NAME=$(jq -r '.planName.value' infra/params.json)
DATABASE_ADMIN_USERNAME=$(jq -r '.sqlDBAdminUsername.value' infra/params.json)
LOCATION=$(jq -r '.resourceGroupLocation.value' infra/params.json)
IMAGE_TAG="DOCKER|docker.io/${DOCKER_USERNAME}/bullpen-blog:latest"

# Getter func for secrets with success/fail check
get_secret() {
  local secret
  secret=$(az keyvault secret show --vault-name "$KEYVAULT_NAME" --name "$1" --query value -o tsv 2>/dev/null) || secret=""

  if [[ -n "$secret" ]]; then
    echo "$secret"
  else
    echo ""
  fi
}

# Setter func for secrets
set_secret() {
  local name="$1"
  local value="$2"

  if [[ -z "$name" || -z "$value" ]]; then
    echo "Usage: set_secret <secret_name> <secret_value>"
    return 1
  fi

  echo "Setting secret '$name' in Key Vault '$KEYVAULT_NAME'..."
  az keyvault secret set --vault-name "$KEYVAULT_NAME" --name "$name" --value "$value" >/dev/null

  echo "✅ Secret '$name' set successfully."
}

# Check if Key Vault exists
if az keyvault show --name "$KEYVAULT_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
  echo "Key Vault exists, skipping creation"
  CREATE_KV=false
else
  CREATE_KV=true
fi

# Check if Database exists
if az postgres flexible-server db list \
  --resource-group "$RESOURCE_GROUP" \
  --server-name "$SQL_SERVER_NAME" \
  --query "[?name=='$DATABASE_NAME']" \
  -o tsv | grep -q "$DATABASE_NAME" &>/dev/null; then
  echo "DB already exists. Skipping creation..."
  CREATE_DB=false
else
  echo "No PostgreSQL DB found, creating new DB..."
  CREATE_DB=true
  DATABASE_ADMIN_PASSWORD=$(openssl rand -base64 32)
  POSTGRES_LISTENING_PORT=5432
  AZURE_POSTGRESQL_SERVER_HOST_SUFFIX=postgres.database.azure.com
  PROD_DB_URI="postgresql+psycopg2://${DATABASE_ADMIN_USERNAME}:${DATABASE_ADMIN_PASSWORD}@${SQL_SERVER_NAME}.${AZURE_POSTGRESQL_SERVER_HOST_SUFFIX}:${POSTGRES_LISTENING_PORT}/${DATABASE_NAME}?sslmode=require"
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
  sqlDBAdminPassword="$DATABASE_ADMIN_PASSWORD" \
  createDatabase=$CREATE_DB \
  createAppServicePlan=$CREATE_ASP \
  createApp=$CREATE_APP \
  webAppLinuxFxVersion="$IMAGE_TAG"

# Adding Secrets
if [ "$CREATE_KV" = true ]; then
  echo "Adding new Secret Key to secrets..."
  SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
  set_secret "SecretKey" "$SECRET_KEY"
fi

if [ "$CREATE_DB" = true ]; then
  echo "Adding new DB Admin password and DB URI to secrets..."
  set_secret "ProdDatabaseAdminPassword" "$DATABASE_ADMIN_PASSWORD"
  set_secret "ProdDatabaseURI" "$PROD_DB_URI"
  az webapp config appsettings set \
    --name "$APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --settings PROD_DB_URI="$PROD_DB_URI"
fi

if [ "$CREATE_APP" = true ]; then
  PROD_SECRET_KEY_VAL="$(get_secret "SecretKey")"
  PROD_DB_URI_VAL="$(get_secret "ProdDatabaseURI")"
  PROD_MAIL_PASSWORD_VAL="$(get_secret "ProdMailPassword")"

  # Only include non-empty secrets
  SETTINGS=()
  [[ -n "$PROD_SECRET_KEY_VAL" ]] && SETTINGS+=(PROD_SECRET_KEY="$PROD_SECRET_KEY_VAL")
  [[ -n "$PROD_DB_URI_VAL" ]] && SETTINGS+=(PROD_DB_URI="$PROD_DB_URI_VAL")
  [[ -n "$PROD_MAIL_PASSWORD_VAL" ]] && SETTINGS+=(PROD_MAIL_PASSWORD="$PROD_MAIL_PASSWORD_VAL")

  if [ "${#SETTINGS[@]}" -gt 0 ]; then
    az webapp config appsettings set \
      --name "$APP_NAME" \
      --resource-group "$RESOURCE_GROUP" \
      --settings "${SETTINGS[@]}"
  else
    echo "⚠️ No secrets found to inject into Web App."
  fi
fi
