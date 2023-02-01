#!/usr/bin/env bash

set -v
docker stop cocalc-test
docker rm cocalc-test
sudo docker push  sagemathinc/cocalc:latest
sudo docker push  sagemathinc/cocalc:`cat current_commit`
