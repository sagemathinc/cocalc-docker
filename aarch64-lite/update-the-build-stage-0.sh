#!/usr/bin/env bash
set -ex
export DOCKER_BUILDKIT=0

docker stop cocalc-lite-test && docker rm cocalc-lite-test
export BRANCH="${BRANCH:-master}"
echo "BRANCH=$BRANCH"
commit=`git ls-remote -h https://github.com/sagemathinc/cocalc $BRANCH | awk '{print $1}'`
echo $commit | cut -c-12 > current_commit
time docker build --build-arg commit=$commit --build-arg BRANCH=$BRANCH --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') -t cocalc-lite-aarch64 $@ ..
docker tag cocalc-lite-aarch64:latest sagemathinc/cocalc-lite-aarch64:latest
docker tag cocalc-lite-aarch64:latest sagemathinc/cocalc-lite-aarch64:`cat current_commit`
docker run --name=cocalc-lite-test -d -p 127.0.0.1:4043:443 sagemathinc/cocalc-lite-aarch64
