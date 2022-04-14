#!/usr/bin/env bash
set -ex

sudo docker stop cocalc-test-lite && sudo docker rm cocalc-test-lite
git pull
export BRANCH="${BRANCH:-master}"
echo "BRANCH=$BRANCH"
commit=`git ls-remote -h https://github.com/sagemathinc/cocalc $BRANCH | awk '{print $1}'`
echo $commit | cut -c-12 > current_commit
time sudo docker build --build-arg commit=$commit --build-arg BRANCH=$BRANCH --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') -f ../Dockerfile-lite -t cocalc-lite $@ ..
sudo docker tag cocalc-lite:latest sagemathinc/cocalc-lite:latest
sudo docker tag cocalc-lite:latest sagemathinc/cocalc-lite:`cat current_commit`
sudo docker run --name=cocalc-test-lite -d -v ~/cocalc-test-lite:/projects -p 4044:443 sagemathinc/cocalc-lite
