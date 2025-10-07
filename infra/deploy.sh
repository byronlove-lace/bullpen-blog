#!/usr/bin/env bash
set -euo pipefail

# Optional: define deployment name
DEPLOYMENT_NAME="bullpen-blog-deployment"

# Location for the subscription-level deployment
LOCATION="northeurope"

# Launch deployment
az deployment sub create \
  --name "$DEPLOYMENT_NAME" \
  --location "$LOCATION" \
  --template-file infra/main.bicep \
  --parameters @infra/params.json
