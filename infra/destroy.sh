#!/usr/bin/env bash
set -euo pipefail

RG_NAME=$(jq -r '.rg_name.value' infra/params.json)

echo "Deleting resource group $RG_NAME..."
az group delete \
  --name "$RG_NAME" \
  --yes \
  --no-wait

echo "Delete initiated."
