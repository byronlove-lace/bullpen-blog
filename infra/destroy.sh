#!/usr/bin/env bash
set -euo pipefail

# Read RG name from params.json
RG_NAME=$(jq -r '.resourceGroupName.value' infra/params.json)

echo "Deleting resource group $RG_NAME..."
az group delete \
  --name "$RG_NAME" \
  --yes \
  --no-wait

echo "Delete initiated."
