#!/usr/bin/env bash
set -e

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
SCRIPTS_PATH="$PROJECT_ROOT/scripts"
LOG_PATH="$PROJECT_ROOT/infra/logs"
PARAMS_FILE="$PROJECT_ROOT/infra/params.json"
KEEP_ALL=false

if [[ ! -f "$PARAMS_FILE" ]]; then
  echo "❌ params.json not found at $PARAMS_FILE"
  return 1
fi

KEYVAULT_NAME=$(jq -r '.keyVaultName.value' "$PARAMS_FILE")
APP_NAME=$(jq -r '.appName.value' "$PARAMS_FILE")
RESOURCE_GROUP_NAME=$(jq -r '.resourceGroupName.value' "$PARAMS_FILE")

# parse -a flag
while getopts "a" opt; do
  case $opt in
  a)
    KEEP_ALL=true
    ;;
  *) ;;
  esac
done

# funcs
find_most_recent_log() {
  pattern="$1"
  latest_file=""
  latest_epoch=0
  latest_ms=0

  for f in "$LOG_PATH"/LogFiles/*${pattern}.log; do
    # extract milliseconds from filename
    ms=$(basename "$f" | sed -E "s/^.*-([0-9]{1,3})_.*\.log$/\1/")
    echo "GOT THE MILLISECONDS: $ms" >&2

    # extract timestamp portion from filename
    ts=$(basename "$f" | sed -E 's/^([0-9]{4})_([0-9]{1,2})_([0-9]{1,2})_([0-9]{1,2})-([0-9]{1,2})-([0-9]{1,2})-[0-9]{1,3}_.*/\1-\2-\3 \4:\5:\6/')
    echo "GOT THE TIMESTAMP: $ts" >&2

    # convert to epoch seconds
    epoch=$(date -d "$ts" +%s 2>/dev/null) || continue
    echo "GOT THE EPOCH: $epoch" >&2

    # compare
    if ((epoch > latest_epoch)) || { ((epoch == latest_epoch)) && ((ms > latest_ms)); }; then
      latest_epoch=$epoch
      latest_ms=$ms
      latest_file="$f"
    fi
  done

  echo "$latest_file"
}

echo "Building container and pushing to Docker Registry."
$SCRIPTS_PATH/build-and-push.sh
echo "Build and push successful."

echo "Deploying container to cloud..."
az webapp config container set \
  --name "$APP_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --container-image-name "$DOCKER_USERNAME"/"$APP_NAME":latest \
  --container-registry-url https://index.docker.io \
  >/dev/null
echo "Deploy succesful."

echo "Restarting Webapp..."
az webapp restart \
  --name "$APP_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  >/dev/null
echo "Restart succesful."

echo -n "Waiting 90 seconds for warmup"
for i in {1..9}; do
  echo -n "."
  sleep 10
done
echo ""

echo "Wait complete. Pulling log files..."
az webapp log download \
  --name "$APP_NAME" \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --log-file "$LOG_PATH/logs.zip" \
  >/dev/null

echo "Log files pulled. Unzipping..."
unzip -o "$LOG_PATH/logs.zip" -d "$LOG_PATH"

echo -n "Log files unzipped...  "
if [ "$KEEP_ALL" = false ]; then
  echo "Removing cruft..."
  rm "$LOG_PATH/logs.zip"
  rm -r "$LOG_PATH/LogFiles/kudu"
  rm -r "$LOG_PATH/LogFiles/webssh"
  rm -r "$LOG_PATH/deployments"
else
  echo "Keeping all logs as requested (-a)."
fi

# find closest logs
closest_default=$(find_most_recent_log "default_docker")

echo -e "Found latest default_docker file: $closest_default"

# copy to latest
[ -n "$closest_default" ] && cp "$closest_default" "$LOG_PATH/LogFiles/latest-default-docker.log"

# optionally delete other logs
if [ "$KEEP_ALL" = false ]; then
  for f in "$LOG_PATH"/LogFiles/*docker.log; do
    [ "$f" != "$closest_default" ] && [ "$f" != "$LOG_PATH/LogFiles/latest-default-docker.log" ] && rm "$f"
    echo "Cleaning up other files"
  done
fi

echo "Latest Default Docker log: $closest_default → latest-default-docker.log"
