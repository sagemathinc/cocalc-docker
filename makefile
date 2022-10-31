build:
	docker build -t cocalc .

build-full:
	docker build --no-cache -t cocalc .

light:
	docker build -t cocalc-light -f Dockerfile-light .

run:
	mkdir -p data/projects && docker run --name=cocalc -d -p 443 -p 80:80 -v `pwd`/data/projects:/projects  -v /opt/magma:/opt/magma:ro -P cocalc

run-light:
	mkdir -p data/projects-light && docker run --name=cocalc-light -d -p 443:443 -p 80:80 -v `pwd`/data/projects:/projects -P cocalc-light


