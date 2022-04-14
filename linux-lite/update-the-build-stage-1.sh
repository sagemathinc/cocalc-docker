#!/usr/bin/env bash

set -v
sudo docker stop cocalc-test-lite
sudo docker rm cocalc-test-lite
sudo docker push  sagemathinc/cocalc-lite:latest
sudo docker push  sagemathinc/cocalc-lite:`cat current_commit`
