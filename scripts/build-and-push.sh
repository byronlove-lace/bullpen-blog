#!/usr/bin/env bash
set -e

IMAGE_NAME=$(basename -s .git "$(git rev-parse --show-toplevel)")
TAG=$(git rev-parse --short HEAD)-$(date +%Y%m%d%H%M%S)

echo "Building $IMAGE_NAME:$TAG"
docker build -t $IMAGE_NAME:$TAG .

echo "Tagging and pushing to $DOCKER_USERNAME/$IMAGE_NAME:$TAG"
docker tag $IMAGE_NAME:$TAG $DOCKER_USERNAME/$IMAGE_NAME:$TAG
docker tag $IMAGE_NAME:$TAG $DOCKER_USERNAME/$IMAGE_NAME:latest

docker push $DOCKER_USERNAME/$IMAGE_NAME:$TAG
docker push $DOCKER_USERNAME/$IMAGE_NAME:latest
