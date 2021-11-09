#!/usr/bin/env bash

set -ev
sudo docker stop cocalc-test
sudo docker rm cocalc-test
sudo docker push  sagemathinc/cocalc-aarch64:latest
sudo docker push  sagemathinc/cocalc-aarch64:`cat current_commit`
