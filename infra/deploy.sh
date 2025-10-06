#!/usr/bin/env bash

set -euo pipefail

az deployment sub create \
  --name bullpen-deployment \
  --location northeurope \
  --template-file infra/rg.bicep \
  --parameters-json @infra/rg.bicep
