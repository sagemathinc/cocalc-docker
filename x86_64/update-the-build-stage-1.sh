#!/usr/bin/env bash

set -v
docker stop cocalc-test
docker rm cocalc-test
docker push  sagemathinc/cocalc:latest
docker push  sagemathinc/cocalc:`cat current_commit`
