#!/usr/bin/env bash

set -v
docker stop cocalc-test
docker rm cocalc-test
sudo docker push  sagemathinc/cocalc-v2:latest
sudo docker push  sagemathinc/cocalc-v2:`cat current_commit`
