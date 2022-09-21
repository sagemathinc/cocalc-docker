#!/usr/bin/env bash

set -v
docker stop cocalc-test-personal
docker rm cocalc-test-personal
docker push  sagemathinc/cocalc-personal-aarch64:latest
docker push  sagemathinc/cocalc-personal-aarch64:`cat current_commit`
