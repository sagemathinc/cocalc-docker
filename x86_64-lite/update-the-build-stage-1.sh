#!/usr/bin/env bash

set -v
docker stop cocalc-test-lite
docker rm cocalc-test-lite
docker push  sagemathinc/cocalc-lite:latest
docker push  sagemathinc/cocalc-lite:`cat current_commit`
