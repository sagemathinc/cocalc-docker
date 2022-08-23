#!/usr/bin/env bash
set -ex
export DOCKER_BUILDKIT=0

docker stop cocalc-test && docker rm cocalc-test
export BRANCH="${BRANCH:-master}"
echo "BRANCH=$BRANCH"
commit=`git ls-remote -h https://github.com/sagemathinc/cocalc $BRANCH | awk '{print $1}'`
echo $commit | cut -c-12 > current_commit
time docker build --build-arg commit=$commit --build-arg BRANCH=$BRANCH --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') -t cocalc-aarch64 $@ ..
docker tag cocalc-aarch64:latest sagemathinc/cocalc-aarch64:latest
docker tag cocalc-aarch64:latest sagemathinc/cocalc-aarch64:`cat current_commit`
docker run --name=cocalc-test -d -p 127.0.0.1:4043:443 sagemathinc/cocalc-aarch64
