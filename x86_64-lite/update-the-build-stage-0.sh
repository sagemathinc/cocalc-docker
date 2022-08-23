#!/usr/bin/env bash
set -ex

docker stop cocalc-test-lite && docker rm cocalc-test-lite
export BRANCH="${BRANCH:-master}"
echo "BRANCH=$BRANCH"
commit=`git ls-remote -h https://github.com/sagemathinc/cocalc $BRANCH | awk '{print $1}'`
echo $commit | cut -c-12 > current_commit
time docker build --build-arg commit=$commit --build-arg BRANCH=$BRANCH --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') -f ../Dockerfile-lite -t cocalc-lite $@ ..
docker tag cocalc-lite:latest sagemathinc/cocalc-lite:latest
docker tag cocalc-lite:latest sagemathinc/cocalc-lite:`cat current_commit`
docker run --name=cocalc-test-lite -d -v ~/cocalc-test-lite:/projects -p 127.0.0.1:4044:443 sagemathinc/cocalc-lite
