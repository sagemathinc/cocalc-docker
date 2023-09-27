#!/usr/bin/env bash

set -v
docker stop cocalc-test-personal
docker rm cocalc-test-personal
docker push  sagemathinc/cocalc-v2-personal:latest
docker push  sagemathinc/cocalc-v2-personal:`cat current_commit`
