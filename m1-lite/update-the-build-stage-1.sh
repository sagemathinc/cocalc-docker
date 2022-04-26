
set -v
docker stop cocalc-lite-test
docker rm cocalc-lite-test
docker push  sagemathinc/cocalc-lite-aarch64:latest
docker push  sagemathinc/cocalc-lite-aarch64:`cat current_commit`
