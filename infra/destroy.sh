#!/usr/bin/env bash
set -euo pipefail

PURGE=false

# parse argument
if [[ "${1-}" == "--purge" ]]; then
  PURGE=true
fi

RESOURCE_GROUP_NAME=$(jq -r '.resourceGroupName.value' infra/params.json)
KEYVAULT_NAME=$(jq -r '.keyVaultName.value' infra/params.json)
APP_SERVICE_PLAN_NAME=$(jq -r '.planName.value' infra/params.json)
WEBAPP_NAME=$(jq -r '.appName.value' infra/params.json)
KEYVAULT_LOCATION=$(jq -r '.resourceGroupLocation.value' infra/params.json)

if $PURGE; then
  echo "Checking if Key Vault '$KEYVAULT_NAME' exists..."
  if az keyvault show --name "$KEYVAULT_NAME" --resource-group "$RESOURCE_GROUP_NAME" &>/dev/null; then
    echo "Deleting Key Vault '$KEYVAULT_NAME'..."
    az keyvault delete --name "$KEYVAULT_NAME" --resource-group "$RESOURCE_GROUP_NAME"
    echo "Purging Key Vault '$KEYVAULT_NAME'..."
    az keyvault purge --name "$KEYVAULT_NAME" --location "$KEYVAULT_LOCATION"
  elif az keyvault show-deleted --name "$KEYVAULT_NAME" &>/dev/null; then
    echo "Key Vault '$KEYVAULT_NAME' was previously show-deleted. Purging now..."
    az keyvault purge --name "$KEYVAULT_NAME" --location "$KEYVAULT_LOCATION"
  else
    echo "Key Vault '$KEYVAULT_NAME' does not exist, skipping purge."
  fi
  # Check if resource group exists
  if [[ "$(az group exists --name "$RESOURCE_GROUP_NAME")" != "true" ]]; then
    echo "Resource group '$RESOURCE_GROUP_NAME' does not exist. Exiting..."
    exit 0
  else
    # delete resource group
    az group delete --name "$RESOURCE_GROUP_NAME" --yes --no-wait
    echo "Resource group '$RESOURCE_GROUP_NAME' found. Deleting..."
  fi
else
  # Delete the Web App
  if az webapp show --name "$WEBAPP_NAME" --resource-group "$RESOURCE_GROUP_NAME" &>/dev/null; then
    echo "Deleting Web App: $WEBAPP_NAME"
    az webapp delete --name "$WEBAPP_NAME" --resource-group "$RESOURCE_GROUP_NAME" --yes
  else
    echo "Web App $WEBAPP_NAME does not exist"
  fi

  # Delete the App Service Plan
  if az appservice plan show --name "$APP_SERVICE_PLAN_NAME" --resource-group "$RESOURCE_GROUP_NAME" &>/dev/null; then
    echo "Deleting App Service Plan: $APP_SERVICE_PLAN_NAME"
    az appservice plan delete --name "$APP_SERVICE_PLAN_NAME" --resource-group "$RESOURCE_GROUP_NAME" --yes
  else
    echo "App Service Plan $APP_SERVICE_PLAN_NAME does not exist"
  fi

  echo "Regular delete complete Resource group, '$RESOURCE_GROUP_NAME', and Key Vault, '$KEYVAULT_NAME' persist."
fi
