#!/usr/bin/env bash
set -ex

docker stop cocalc-test-personal && docker rm cocalc-test-personal
export BRANCH="${BRANCH:-master}"
echo "BRANCH=$BRANCH"
commit=`git ls-remote -h https://github.com/sagemathinc/cocalc $BRANCH | awk '{print $1}'`
echo $commit | cut -c-12 > current_commit
time docker build --build-arg commit=$commit --build-arg BRANCH=$BRANCH --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') -f ../Dockerfile-personal -t cocalc-personal $@ ..
docker tag cocalc-personal:latest sagemathinc/cocalc-personal-aarch64:latest
docker tag cocalc-personal:latest sagemathinc/cocalc-personal-aarch64:`cat current_commit`
docker run --name=cocalc-test-personal -d -v  ~/cocalc-test-personal:/home/user/cocalc/src/data -p 127.0.0.1:5123:5000 sagemathinc/cocalc-personal-aarch64
