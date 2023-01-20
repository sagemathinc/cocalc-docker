#!/usr/bin/env bash

set -v
docker stop cocalc-personal-test
docker rm cocalc-personal-test
docker push  sagemathinc/cocalc-personal-aarch64:latest
docker push  sagemathinc/cocalc-personal-aarch64:`cat current_commit`
