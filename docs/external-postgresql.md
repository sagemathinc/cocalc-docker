# Using CoCalc-Docker with an External PostgreSQL Database

By default, `cocalc-docker` runs a PostgreSQL database inside the `cocalc-docker` [Docker 
container](https://www.docker.com/resources/what-container/). If desired, `cocalc-docker` can 
instead connect to an externally-hosted PostgreSQL server by setting some environment variables and 
a password file when creating the `cocalc-docker` container. In particular, if the environment 
variable `PGHOST` is set, then `cocalc-docker` will not start an internal database and instead 
relies on configuration to connect to an external database.

In this tutorial, we connect `cocalc-docker` to a PostgreSQL database (with optional SSL
encryption) running on our local machine via Docker. 

The following environment variables are used by `cocalc-docker` to configure this connection:

| Variable Name                      | Description                            | Default                          |
|------------------------------------|----------------------------------------|----------------------------------|
| `PGHOST`                           | External database host/port.           | `/projects/postgres/data/socket` |
| `PGUSER`                           | PostgreSQL user to connect as.         | `smc`                            |
| `SMC_DB`                           | Database name                          | `smc`                            |
| `SMC_DB_SSL_CA_FILE`               | Server certificate authority file path |                                  |
| `SMC_DB_SSL_CLIENT_CERT_FILE`      | Client certificate file path           |                                  |
| `SMC_DB_SSL_CLIENT_KEY_FILE`       | Client certificate key file path       |                                  |
| `SMC_DB_SSL_CLIENT_KEY_PASSPHRASE` | Client certificate key passphrase      |                                  |

> **Note**: The database password is mounted into the Docker container via the filesystem so that 
> it is not explicitly passed via the command line. Inside the Docker container, this file resides
> at `/projects/secrets/postgres`.

## Tutorial

### Create a Docker Network

Since we're using Docker to run both PostgreSQL and CoCalc Docker as separate containers, these 
two services by default are isolated from one another and cannot communicate. To resolve this, we'll
create a [Docker networks](https://docs.docker.com/network/) in order to specify that these two 
containers are allowed to connect:

```sh
~ $ docker network create -d bridge cocalc-network
```

> **Note:** This step is only required since we are using Docker to run a local PostgreSQL instance.
> When connecting to an externally-managed database (e.g., [Supabase](https://supabase.com/), 
> [Amazon RDS](https://aws.amazon.com/rds/), etc.), it is not necessary to create a Docker network.

### Generate SSL certificates*

> **Note:** Generating self-signed SSL certificates is an optional part of this tutorial. Steps 
> which must be followed to use an SSL-encrypted database connection are marked with an asterisk 
> (*).

First, we'll generate some SSL certificates with [OpenSSL](https://www.openssl.org/) in order 
to secure our connection between CoCalc Docker and PostgreSQL. For the sake of completeness, we will 
generate a server-side 
[root certificate authority (CA)](https://en.wikipedia.org/wiki/Root_certificate) and use it to 
sign a server certificate for PostgreSQL to present to CoCalc Docker. We'll also generate a client 
certificate which CoCalc Docker will use to authenticate with our PostgreSQL server in what is 
commonly known as 
[mutual TLS authentication](https://www.cloudflare.com/learning/access-management/what-is-mutual-tls/).

We'll need eight files in total, of which seven will be generated via command-line:

- `ca.key`: The private key for the [Certificate Authority](https://en.wikipedia.org/wiki/Certificate_authority).
- `ca.crt`: The [self-signed certificate](https://en.wikipedia.org/wiki/Self-signed_certificate) 
             which acts as the root certificate authority.
- `server.key`: The private key for the server.
- `server.csr`: The [Certificate Signing Request](https://en.wikipedia.org/wiki/Certificate_signing_request) for the server.
- `server.crt`: The signed certificate for the server.
- `client.key`: The private key for the client.
- `client.csr`: The Certificate Signing Request for the client.
- `client.crt`: The signed certificate for the client.

First, we'll create a directory in which to store these files:

```sh
~ $ mkdir -p ~/cocalc-extdb/ssl
```

Now we can generate the above files in order. First, we generate the requisite private 
key/certificate pair to establish a root certificate authority. You'll be prompted for some 
information to embed into the certificate authority. Go ahead and enter whatever information feels 
right. Unless otherwise specified, this tutorial assumes that all default values are used.

```sh
~ $ openssl req -nodes -new -x509 -days 3650 -keyout ~/cocalc-extdb/ssl/ca.key -out ~/cocalc-extdb/ssl/ca.crt
```

Next, we'll create a server certificate/key pair for PostgreSQL to use. This time, we need to create
a certificate signing request (CSR), which our newly-minted certificate authority will sign. You'll 
be prompted for some information again; **note that the certificate Common Name MUST be set to 
`postgres`** but all other configuration may be set to whatever you wish (or left empty).

```sh
~ $ openssl req -nodes -new -keyout ~/cocalc-extdb/ssl/server.key -out ~/cocalc-extdb/ssl/server.csr
...
Common Name (e.g. server FQDN or YOUR name) []:postgres
...
```

With our CSR in hand, we'll create a configuration file for signing our server certificate with our
certificate authority:

```sh
~ $ echo "[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no
[req_distinguished_name]
CN = postgres
[v3_req]
subjectAltName = @alt_names
[alt_names]
DNS.1 = postgres
DNS.2 = localhost" > ~/cocalc-extdb/ssl/server.cnf
```

Next, we sign the server certificate (to be valid for five years) with the certificate authority we 
generated in the first step:

```sh
~ $ openssl x509 -req -days 1825 -in ~/cocalc-extdb/ssl/server.csr \
    -CA ~/cocalc-extdb/ssl/ca.crt \
    -CAkey ~/cocalc-extdb/ssl/ca.key \
    -extfile ~/cocalc-extdb/ssl/server.cnf \
    -out ~/cocalc-extdb/ssl/server.crt \
    -extensions v3_req \
    -CAcreateserial
```

Lastly, we repeat the above steps to generate a client certificate for CoCalc Docker to use as 
authentication against the client database. First, we generate the certificate signing request 
and key pair. **When prompted for the Common Name, enter `cocalc` for this certificate**:

```sh
~ $ openssl req -nodes -new -keyout ~/cocalc-extdb/ssl/client.key -out ~/cocalc-extdb/ssl/client.csr
...
Common Name (e.g. server FQDN or YOUR name) []:cocalc
...
```

As before, we create a configuration file to specify some necessary configuration when signing the 
client certificate:

```sh
~ $ echo "[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no
[req_distinguished_name]
CN = cocalc
[v3_req]
subjectAltName = @alt_names
[alt_names]
DNS.1 = cocalc" > ~/cocalc-extdb/ssl/client.cnf
```

...and now we can finally sign this client certificate request (again, for five years):

```sh
~ $ openssl x509 -req -days 1825 -in ~/cocalc-extdb/ssl/client.csr \
    -CA ~/cocalc-extdb/ssl/ca.crt \
    -CAkey ~/cocalc-extdb/ssl/ca.key \
    -extfile ~/cocalc-extdb/ssl/client.cnf \
    -out ~/cocalc-extdb/ssl/client.crt \
    -extensions v3_req \
    -CAcreateserial
```

With all the SSL certificates we could possibly desire, we're ready to move on to actually getting
everything up and running.

### Create the PostgreSQL container

For the sake of completeness, we'll start with a base Ubuntu image and walk through the full 
PostgreSQL installation and configuration process in order to better understand how each part works.

To begin, we create a long-running Ubuntu Docker container which will serve PostgreSQL on port 
5432, and then install PostgreSQL 14 via [apt](https://ubuntu.com/server/docs/package-management):

```sh
~ $ docker run -d --name=postgres --network=cocalc-network ubuntu:22.04 sleep infinity
~ $ docker exec postgres bash -c 'apt update && DEBIAN_FRONTEND=noninteractive apt install -y postgresql-14'
```

##### Copy SSL Certificates*

If you created SSL certificates earlier, we'll need to copy those files into our 
container; here, we simply copy them in via `docker cp` instead of using a 
[bind mount](https://docs.docker.com/storage/bind-mounts/) in order to ease file permissions 
management:

```sh
~ $ docker cp ~/cocalc-extdb/ssl postgres:/var/lib/postgresql/14/main/
~ $ docker exec postgres bash -c 'chown postgres:postgres /var/lib/postgresql/14/main/ssl -R'
```


##### Configure PostgreSQL

From here, we'll create the necessary databases and credentials we need in order to run CoCalc. That 
is, we'll create a `cocalc` database and a `cocalc` user with `cocalc` as the password. If you are 
planning to use this container anywhere other than your own computer for personal use, we 
**highly recommend** using at least a randomly-generated password. Run the following command to 
configure the PostgreSQL server to listen on all IP addresses:

```sh
~ $ docker exec -it postgres bash
root@56103ab68131:/# echo "listen_addresses = '*'" >> /etc/postgresql/14/main/postgresql.conf
```

##### Configure Authentication

Next, run the following command to configure password authentication:

```sh
# Without SSL:

root@56103ab68131:/# echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/14/main/pg_hba.conf

# or, if SSL is to be used:

root@56103ab68131:/# echo "hostssl all all 0.0.0.0/0 cert" >> /etc/postgresql/14/main/pg_hba.conf
root@56103ab68131:/# echo "ssl = on
ssl_ca_file = 'ssl/ca.crt'
ssl_cert_file = 'ssl/server.crt'
ssl_key_file = 'ssl/server.key'" >> /etc/postgresql/14/main/postgresql.conf
```

#### Create Postgres User and Database

```sh
root@56103ab68131:/# service postgresql start
root@56103ab68131:/# su - postgres
postgres@56103ab68131:~$ psql
psql (14.10 (Ubuntu 14.10-0ubuntu0.22.04.1))
Type "help" for help.

postgres=# create user cocalc with encrypted password 'cocalc';
CREATE ROLE
postgres=# create database cocalc;
CREATE DATABASE
postgres=# grant all privileges on database cocalc to cocalc;
GRANT
postgres=# exit
postgres@56103ab68131:~$ exit
root@56103ab68131:/# exit
```

### Run CoCalc Docker

#### Create Credentials File

We are now ready to run CoCalc Docker with the database instance we created. We first need to create
a password file from which `cocalc-docker` will read database credentials:

```sh
~ $ mkdir -p ~/cocalc-extdb/secrets
~ $ echo "cocalc" > ~/cocalc-extdb/secrets/postgres
```

> **Note:** For security reasons, permissions on the host directory `~/cocalc-extdb/secrets/` 
> should be very restrictive (i.e., root only) so that normal users can't read the password.
 
> **Note:** This step is technically optional if you are only interested in client certificate 
> authentication. Since that use-case is somewhat rare however, we treat this as a required step.

#### Start the Container

Finally, we run `cocalc-docker` itself, attaching it to the Docker network we created earlier and
mounting our secrets file into the running container:

```sh
# Without SSL:

~ $ docker run -d --name=cocalc -p 5123:443 --network=cocalc-network \
    -e PGHOST=postgres \
    -e PGUSER=cocalc \
    -e SMC_DB=cocalc \
    -v ~/cocalc-extdb:/projects \
    sagemathinc/cocalc-docker
    
# or, if SSL is to be used:

~ $ docker run -d --name=cocalc -p 5123:443 --network=cocalc-network \
    -e PGHOST=postgres \
    -e PGUSER=cocalc \
    -e SMC_DB=cocalc \
    -e SMC_DB_SSL_CA_FILE=/projects/ssl/ca.crt \
    -e SMC_DB_SSL_CLIENT_CERT_FILE=/projects/ssl/client.crt \
    -e SMC_DB_SSL_CLIENT_KEY_FILE=/projects/ssl/client.key \
    -v ~/cocalc-extdb:/projects \
    sagemathinc/cocalc-docker
```

To view CoCalc logs, run:

```sh
~ $ docker logs cocalc
```
Once everything is up and running, you should be able to view CoCalc in your browser at
https://localhost:5123.

## Try it out

Connect to https://localhost:5123 and make an account.  Then get a shell in your database container and confirm that your account is listed in the database!

```sh
~ $ docker exec -it postgres bash
root@56103ab68131:/# su - postgres
postgres@56103ab68131:~$ PGHOST=localhost PGUSER=cocalc psql
Password for user cocalc: 
psql (14.6 (Ubuntu 14.6-0ubuntu0.22.04.1))
cocalc=> select account_id, email_address from accounts;
              account_id              |  email_address   
--------------------------------------+------------------
 1111f1fb-0769-45f3-a115-d14a6dc37362 |  wstein@gmail.com
 
cocalc=> exit
postgres@56103ab68131:~$ exit
root@56103ab68131:/# exit
```

### Stopping CoCalc

Once you're done running CoCalc locally, you can run the following commands to stop the `cocalc` and
`postgres` containers we created:

```sh
~ $ docker stop postgres cocalc
```

...and to pick up where you left off, simply run:

```sh
~ $ docker start postgres cocalc
~ $ docker exec postgres service postgresql start
```

## Clean Up

Run the following commands to remove the Docker containers we created in this tutorial along 
with the data stored in the `~/cocalc-extdb` we created:

> **Warning:** These commands will delete all CoCalc data, including accounts, projects, notebooks,
> etc. Only do this if you want to completely remove CoCalc from your machine. If you're interested
> in keeping your data around for a long period of time or on a shared server, we recommend learning
> more about [persistent data storage with Docker](https://docs.docker.com/storage/). Alternatively,
> if you're interested in a robust, reliable, and scalable CoCalc solution, check out 
> [CoCald Cloud](https://doc.cocalc.com/cocalc-cloud.html) to see if it meets your needs.

```sh
~ $ docker rm -f postgres cocalc
~ $ docker network rm cocalc-network
~ $ rm -rf ~/cocalc-extdb/
```
> **Warning:** You may need to prepend `sudo` to the last command, since Docker automatically 
> creates some files there which are owned by the root user.
