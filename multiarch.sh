#!/usr/bin/env bash

set -ev

if [ $# -lt 1 ]; then
  echo "Error: At least one argument is required."
  exit 1
fi

export IMAGE="$1"
export ARCH_TAG="${2:-latest}"
export TAG="${3:-$ARCH_TAG}"

echo IMAGE=$IMAGE
echo ARCH_TAG=$ARCH_TAG
echo TAG=$TAG

docker manifest create   $IMAGE:$TAG $IMAGE-x86_64:$ARCH_TAG $IMAGE-arm64:$ARCH_TAG --amend
docker manifest annotate $IMAGE:$TAG $IMAGE-x86_64:$ARCH_TAG --os linux --arch amd64
docker manifest annotate $IMAGE:$TAG $IMAGE-arm64:$ARCH_TAG  --os linux --arch arm64
docker manifest push     $IMAGE:$TAG
