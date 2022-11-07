cocalc-data=/scratch/cocalc-data
common_options=--name=cocalc -d -p 443:443  -v $(cocalc-data)/projects:/projects  -v /opt/magma:/opt/magma:ro  -v /etc/letsencrypt/:/etc/letsencrypt/:ro --cap-add=NET_ADMIN -P cocalc
build:
	docker build -t cocalc .

ssl:
	mkdir -p $(cocalc-data)
	if [ -e $(cocalc-data)/projects/conf/cert/cert.pem ]; then rm $(cocalc-data)/projects/conf/cert/cert.pem; fi
	if [ -e $(cocalc-data)/projects/conf/cert/key.pem ]; then rm $(cocalc-data)/projects/conf/cert/key.pem; fi
	ln -s /etc/letsencrypt/live/chatelet.mit.edu/cert.pem $(cocalc-data)/projects/conf/cert/cert.pem
	ln -s /etc/letsencrypt/live/chatelet.mit.edu/privkey.pem $(cocalc-data)/projects/conf/cert/key.pem

build-full:
	docker build --no-cache -t cocalc .
	mkdir -p $(cocalc-data)

light:
	docker build -t cocalc-light -f Dockerfile-light .

run:
	docker run $(common_options)

test:
	docker run --rm $(common_options)
