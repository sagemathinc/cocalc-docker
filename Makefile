DOCKER_USER=sagemathinc

BRANCH=master

BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

COMMIT=$(shell git ls-remote -h https://github.com/sagemathinc/cocalc $(BRANCH) | awk '{print $$1}')

cocalc-docker:
	docker build --build-arg commit=$(COMMIT) --build-arg BRANCH=$(BRANCH) --build-arg BUILD_DATE=$(BUILD_DATE) -t cocalc-docker .

run-cocalc-docker:
	docker run --name=cocalc-docker -d -p 127.0.0.1:4043:443 cocalc-docker

rm-cocalc-docker:
	docker stop cocalc-docker
	docker rm cocalc-docker

push-cocalc-docker:
	exit 1

lite:
	exit 1


personal:
	exit 1
