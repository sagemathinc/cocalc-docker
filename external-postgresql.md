# Using CoCalc-Docker with an External PostgreSQL Database

By default cocalc-docker runs a PostgreSQL database inside the cocalc-docker container.
You can use your own external database with any user and password that you want instead
by setting some environment variables and a password file when creating the cocalc-docker
container.  The following tutorial illustrates how to do this.  To make the tutorial
self contained, we create a standalone docker container just for running PostgreSQL,
and a separate cocalc-docker container that uses that postgresql container.  However,
in your case you might point cocalc-docker at some entirely different postgresql server.

## Tutorial

We 

```sh
~ $ docker run -d --name=postgres -p 127.0.0.1:6000:5432  ubuntu:22.04 sleep infinity
~ $ docker exec -it pg bash
```

```sh
root@56103ab68131:/# apt update
root@56103ab68131:/# DEBIAN_FRONTEND=noninteractive  apt install postgresql
root@56103ab68131:/# service postgresql start
root@56103ab68131:/# su - postgres
postgres@56103ab68131:~$ createuser smc
postgres@56103ab68131:~$ psql
psql (14.6 (Ubuntu 14.6-0ubuntu0.22.04.1))
Type "help" for help.

postgres=# create user cocalc with encrypted password 'cocalc';
CREATE ROLE
postgres=# create database cocalc;
CREATE DATABASE
postgres=# grant all privileges on database cocalc to cocalc;
GRANT
```

```sh
~ $ mkdir -p ~/cocalc-extdb/secrets
~ $ echo "cocalc" > ~/cocalc-extdb/secrets/postgres

docker run --name=cocalc-personal-extdb -e PGHOST=127.0.0.1:6000 -e PGUSER=cocalc -e PGDATABASE=cocalc  -d -p 127.0.0.1:5123:5000 -v  ~/cocalc-extdb:/projects sagemathinc/cocalc-personal-aarch64

```


## Clean Up

```sh
~ $ docker stop postgres
~ $ docker rm postgres
~ $ docker stop cocalc-personal-extdb
~ $ docker rm cocalc-personal-extdb
~ $ rm -rf ~/cocalc-extdb/
```


