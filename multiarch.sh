#!/usr/bin/env bash

set -ev

if [ $# -lt 1 ]; then
  echo "Error: At least one argument is required."
  exit 1
fi

export IMAGE="$1"
export TAG="${2:-latest}"

echo IMAGE=$IMAGE
echo TAG=$TAG

docker manifest create   $IMAGE:$TAG $IMAGE-x86_64:$TAG $IMAGE-arm64:$TAG --amend
docker manifest annotate $IMAGE:$TAG $IMAGE-x86_64:$TAG --os linux --arch amd64
docker manifest annotate $IMAGE:$TAG $IMAGE-arm64:$TAG  --os linux --arch arm64
docker manifest push     $IMAGE:$TAG