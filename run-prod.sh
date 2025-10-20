#!/bin/bash
set -euo pipefail

# run-prod.sh - spins up Docker container with Azure KV secrets

# Remove any existing container with the same name
docker rm -f bullpen-blog 2>/dev/null || true

# Load Key Vault name from params.json
KEYVAULT_NAME=$(jq -r '.keyVaultName.value' infra/params.json)

# Function to fetch a secret from Azure Key Vault
get_secret() {
  az keyvault secret show --vault-name "$KEYVAULT_NAME" --name "$1" --query value -o tsv
}

# Dynamically build environment variable arguments
ENV_VARS=(
  -e PROD_SECRET_KEY="$(get_secret "SecretKey")"
  -e PROD_DB_URI="$(get_secret "ProdDatabaseURI")"
  -e PROD_WEBAPP_HOSTNAME="$(az webapp show --name bullpen-blog --resource-group bullpen-blog-resource-group --query defaultHostName -o tsv)"
  -e PROD_MAIL_SERVER=smtp.mailgun.org
  -e PROD_MAIL_USERNAME=jumbodiaz@sandbox243518a022454790a2eec9499b881f9d.mailgun.org
  -e PROD_MAIL_PASSWORD="$(get_secret "ProdSandboxMailPassword")"
  -e FLASK_CONFIG=docker
)

# Run Docker container with dynamically fetched secrets
docker run --name bullpen-blog -d -p 8000:5000 "${ENV_VARS[@]}" bullpen-blog:latest
