 #!/usr/bin/env bash
set -v
sudo docker stop cocalc-test
sudo docker rm cocalc-test
sudo docker push  sagemathinc/cocalc:latest
sudo docker push  sagemathinc/cocalc:`cat current_commit`
