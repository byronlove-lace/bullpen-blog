#!/usr/bin/env bash
set -euo pipefail

# Optional: define deployment name
DEPLOYMENT_NAME="bullpen-blog-deployment"

# Location for the subscription-level deployment
LOCATION="northeurope"

# Dynamically retrieve current user's Azure AD objectId for Key Vault role assignment
OFFICER_PRINCIPAL_ID=$(az ad signed-in-user show --query objectId -o tsv)

RESOURCE_GROUP=$(jq -r '.resourceGroupName.value' infra/params.json)
KEYVAULT_NAME=$(jq -r '.keyVaultName.value' infra/params.json)

# Check if Key Vault exists
if az keyvault show --name "$KEYVAULT_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
  echo "Key Vault exists, skipping creation"
  CREATE_KV=false
else
  CREATE_KV=true
fi

# Launch deployment
az deployment sub create \
  --name "$DEPLOYMENT_NAME" \
  --location "$LOCATION" \
  --template-file infra/main.bicep \
  --parameters @infra/params.json \
  officerPrincipalId=$OFFICER_PRINCIPAL_ID \
  createKeyVault=$CREATE_KV
