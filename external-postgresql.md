# Using CoCalc-Docker with an External PostgreSQL Database

By default cocalc-docker runs a PostgreSQL database inside the cocalc-docker container.
You can use your own external database with any user and password that you want instead
by setting some environment variables and a password file when creating the cocalc-docker
container.  The following tutorial illustrates how to do this.  To make the tutorial
self contained, we create a standalone docker container just for running PostgreSQL,
and a separate cocalc-docker container that uses that postgresql container.  However,
in your case you might point cocalc-docker at some entirely different postgresql server.

## Tutorial

We create a docker container serving postgresql to port 6000 only
on our local machine (not the external network).  First create
the container.

```sh
~ $ docker run -d --name=postgres -p 127.0.0.1:6000:5432  ubuntu:22.04 sleep infinity
~ $ docker exec -it postgres bash
```

Next install postgresql and create a cocalc user and cocalc database with "cocalc" as the password.  You can change the password to something random if you want to use this in production.

```sh
root@56103ab68131:/# apt update && DEBIAN_FRONTEND=noninteractive  apt install -y postgresql
root@56103ab68131:/# echo "listen_addresses = '*'" >> /etc/postgresql/14/main/postgresql.conf
root@56103ab68131:/# echo "host all all 0.0.0.0/0  md5" >> /etc/postgresql/14/main/pg_hba.conf
root@56103ab68131:/# service postgresql start
root@56103ab68131:/# su - postgres
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

Next we create a cocalc-personal server that uses the database
we just started and serves cocalc on port 5123 only on localhost.
Notice that we write the password to a file which is mounted into
the container.  WARNING: With cocalc-personal there is only one non-root user in the container so any user can read the password file.
With cocalc-lite and cocalc-docker, you should ensure that 
the permissions on this directory ~/cocalc-extdb/secrets/ are
very restrictive, i.e., root only, so that normal users can't
read the password.

Get the ip address of the postgres server, which we will use below:

```sh
~ $ docker inspect postgres | grep IPAddress\"
 "IPAddress": "172.17.0.4",
          "IPAddress": "172.17.0.4",
```

For cocalc-docker or cocalc-lite:

```sh
~ $ mkdir -p ~/cocalc-extdb/secrets
~ $ echo "cocalc" > ~/cocalc-extdb/secrets/postgres
~ $ docker run --name=cocalc-lite-extdb -e PGHOST=172.17.0.4 -e PGUSER=cocalc -e PGDATABASE=cocalc  -d -p 127.0.0.1:5123:5000 -v  ~/cocalc-extdb:/projects sagemathinc/cocalc-lite-aarch64
```

For cocalc-personal:
```sh
~ $ mkdir -p ~/cocalc-extdb/secrets
~ $ echo "cocalc" > ~/cocalc-extdb/secrets/postgres
~ $ docker run --name=cocalc-personal-extdb -e PGHOST=172.17.0.4 -e PGUSER=cocalc -e PGDATABASE=cocalc  -d -p 127.0.0.1:5123:5000 -v  ~/cocalc-extdb:/home/user/cocalc/src/data/ sagemathinc/cocalc-personal-aarch64
```

## Try it out

Connect to https://localhost:5123 and make an account.  Then get a shell in your database container and confirm that your account is listed in that database!

```sh
~ $ docker exec -it postgres bash
root@56103ab68131:/# su - postgres
postgres@d6d51811ce9c:~$ PGHOST=localhost PGUSER=cocalc psql
Password for user cocalc: 
psql (14.6 (Ubuntu 14.6-0ubuntu0.22.04.1))
cocalc=> select account_id, email_address from accounts;
              account_id              |  email_address   
--------------------------------------+------------------
 1111f1fb-0769-45f3-a115-d14a6dc37362 | wstein@gmail.com
 b26d3e0a-3884-4f98-8b12-0a1504b1f78b |                        (only see this for cocalc-personal)
```

## Clean Up

```sh
~ $ docker stop postgres
~ $ docker rm postgres
~ $ docker stop cocalc-personal-extdb
~ $ docker rm cocalc-personal-extdb
~ $ rm -rf ~/cocalc-extdb/
```

