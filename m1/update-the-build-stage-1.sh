
set -v
docker stop cocalc-test
docker rm cocalc-test
docker push  sagemathinc/cocalc-aarch64:latest
docker push  sagemathinc/cocalc-aarch64:`cat current_commit`
