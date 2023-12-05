DOCKER_USER=sagemathinc
BRANCH=master
BUILD_DATE=$(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
COMMIT=$(shell git ls-remote -h https://github.com/sagemathinc/cocalc $(BRANCH) | awk '{print $$1}')

# ARCH = '-x86_64' or '-arm64'
ARCH=$(shell uname -m | sed 's/x86_64/-x86_64/;s/arm64/-arm64/;s/aarch64/-arm64/')

# Update this for each new release.
TAG=1.0

SAGEMATH_TAG=10.2
cocalc-docker:
	docker build \
		--build-arg SAGEMATH_TAG=$(SAGEMATH_TAG) \
		--build-arg ARCH=$(ARCH) \
		--build-arg COMMIT=$(COMMIT) \
		--build-arg BRANCH=$(BRANCH) \
		--build-arg BUILD_DATE=$(BUILD_DATE) -t cocalc-docker$(ARCH) .
	docker tag cocalc-docker$(ARCH) $(DOCKER_USER)/cocalc-docker$(ARCH):$(TAG)

run-cocalc-docker:
	docker run --name=cocalc-docker -d -p 127.0.0.1:4043:443 $(DOCKER_USER)/cocalc-docker$(ARCH):$(TAG)

rm-cocalc-docker:
	docker stop cocalc-docker
	docker rm cocalc-docker

push-cocalc-docker:
	docker push $(DOCKER_USER)/cocalc-docker$(ARCH):$(TAG)

assemble-cocalc-docker:
	./multiarch.sh $(DOCKER_USER)/cocalc-docker $(TAG)
	docker tag $(DOCKER_USER)/cocalc-docker latest
	docker push $(DOCKER_USER)/cocalc-docker:latest

cocalc-core:
	cd src && docker build --build-arg commit=$(COMMIT) --build-arg BRANCH=$(BRANCH) --build-arg BUILD_DATE=$(BUILD_DATE) -t cocalc-core$(ARCH) . -f cocalc-core/Dockerfile
	docker tag cocalc-core$(ARCH) $(DOCKER_USER)/cocalc-core:$(COMMIT)

assemble-cocalc-core:
	./multiarch.sh $(DOCKER_USER)/cocalc-core $(COMMIT)

pytorch:
	cd src && docker build --build-arg commit=$(COMMIT) --build-arg BRANCH=$(BRANCH) --build-arg BUILD_DATE=$(BUILD_DATE) -t cocalc-docker-pytorch . -f pytorch/Dockerfile
	docker tag cocalc-docker-pytorch $(DOCKER_USER)/cocalc-docker-pytorch:$(TAG)

run-pytorch:
	docker run --name=cocalc-docker-pytorch -d -p 127.0.0.1:4043:443 cocalc-docker-pytorch

rm-pytorch:
	docker stop cocalc-docker-pytorch
	docker rm cocalc-docker-pytorch

push-pytorch:
	docker push $(DOCKER_USER)/cocalc-docker-pytorch:$(TAG)
