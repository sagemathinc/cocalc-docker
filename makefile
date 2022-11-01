build:
	sudo docker build -t cocalc .

build-full:
	docker build --no-cache -t cocalc .

light:
	docker build -t cocalc-light -f Dockerfile-light .

run:
	mkdir -p data/projects && sudo docker run --name=cocalc -d -p 443:443  -v `pwd`/data/projects:/projects  -v /opt/magma:/opt/magma:ro  -v /etc/letsencrypt/:/etc/letsencrypt/:ro --cap-add=NET_ADMIN -P cocalc

test:
	mkdir -p data/projects && sudo docker run --rm --name=cocalc -p 443:443 -v /etc/letsencrypt/:/etc/letsencrypt/:ro -v `pwd`/data/projects:/projects  -v /opt/magma:/opt/magma:ro -P  --cap-add=NET_ADMIN cocalc

run-light:
	mkdir -p data/projects-light && docker run --name=cocalc-light -d -p 443:443  -v `pwd`/data/projects:/projects -P cocalc-light


