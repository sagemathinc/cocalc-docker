# CoCalc Docker image

This is a self-contained single-image multi-user CoCalc server.

**STATUS:**
  - This is _**not blatantly insecure** from outside attack: the database has a long random password, user accounts are separate, encrypted SSL communication is used by default, etc.
  - That said, **a determined user with an account can easily access or change files of other users in the same container!** Use this for personal use, behind a firewall, or with an account creation token, so that only other people you trust create accounts.  Don't make one of these publicly available with important data in it and no account creation token! See [issue 2031]( https://github.com/sagemathinc/cocalc/issues/2031).
  - See the [open docker-related CoCalc issues](https://github.com/sagemathinc/cocalc/issues?q=is%3Aopen+is%3Aissue+label%3AA-docker), which may include several issues.

## Instructions

Install Docker on your computer (e.g., `apt-get install docker.io` on Ubuntu).   Make sure you have at least 8GB disk space free, then type

    docker run --name=cocalc -d -v ~/cocalc:/projects -p 443:443 sagemathinc/cocalc

wait a minute, then visit https://localhost.  It is expected that you'll see a "Your connection is not private" warning, since you haven't set up a security certificate.  Click "Show advanced" and "Proceed to localhost (unsafe)".

NOTES:
 - This Docker image only supports 64-bit Intel.
 - If you get an error about the Docker daemon, instead run `sudo docker ...`.
 - CoCalc will NOT work over insecure port 80.  A previous version of these direction suggested using -p 80:80 above and visiting http://localhost, [which will not work](https://github.com/sagemathinc/cocalc/issues/2000).

The above command will first download the image, then start CoCalc, storing your data in the directory `~/cocalc` on your computer. If you want to store your worksheets and edit history elsewhere, change `~/cocalc` to something else.  Once your local CoCalc is running, open your web browser to https://localhost.

The docker container is called `cocalc` and you can refer to the container and use commands like:

    $ docker stop cocalc
    $ docker start cocalc

You can watch the logs:

    $ docker logs cocalc -f

However, these logs often don't work.  In that case get a bash shell in the terminal and look at the logs using tail:

    $ docker exec -it cocalc bash
    $ tail -f /var/log/hub.log


### Clock skew on OS X

It is **critical** that the Docker container have the correct time, since CoCalc assumes that the server has the correct time.
On a laptop running Docker under OS X, the clock will probably get messed up any time you suspend/resume your laptop.  This workaround might work for you: https://github.com/arunvelsriram/docker-time-sync-agent/.


### SSH port forwarding

If you're running this docker image on a remote server and want to use ssh port forwarding to connect, type

    ssh -L 8080:localhost:443 username@remote_server

then open your web browser to https://localhost:8080

For **enhanced security**, make the container only listen on localhost

    docker stop cocalc
    docker rm cocalc
    docker run --name=cocalc -d -v ~/cocalc:/projects -p  127.0.0.1:443:443 sagemathinc/cocalc

Then the **only way** to access your CoCalc server is to type the following on your local computer

    ssh -L 8080:localhost:443 username@remote_server

and open your web browser to https://localhost:8080

### SSH into a project

Instead of doing

    docker run --name=cocalc -d -v ~/cocalc:/projects -p 443:443 sagemathinc/cocalc

do this:

    docker run --name=cocalc -d -v ~/cocalc:/projects -p 443:443 -p <your ip address>:2222:22  sagemathinc/cocalc

Then you can do

    ssh projectid@<your ip address> -p 2222



### Make a user an admin

Get a bash shell insider the container, then connect to the database and make a user (me!) an admin as follows:

    $ docker exec -it cocalc bash
    root@931045eda11f:/# coffee
    coffee> require 'c'
    coffee> db.make_user_admin(email_address:'wstein@gmail.com', cb:done())

Obviously, you should really make the user you created (with its email address) an admin, not me!
Refresh your browser, and then you should see an extra admin panel in the lower right of accounts settings; you can also open any project by directly visiting its URL.

#### Account Creation Token

After making your main account an admin as above, search for "Account Creation Token" in the Admin tab. Put some random  string there and other people will not be able to create accounts in your CoCalc container, without knowing that token.

### Terminal Height

If `docker exec -it cocalc bash` doesn't seem to give you the right terminal height, e.g. content is only displayed in the uppper part of the terminal, this workaround may help when launching bash:
```
docker exec -e COLUMNS="`tput cols`" -e LINES="`tput lines`" -it cocalc bash
```
More information on this issue is in [moby issue 33794](https://github.com/moby/moby/issues/33794).

## Your data

If you started the container as above, there will be a directory ~/cocalc on your host computer that contains **all** data and files related to your projects and users -- go ahead and verify that it is there before ugrading.   It might look like this:

    Williams-MacBook-Pro:~ wstein$ ls cocalc
    be889c14-dc96-4538-989b-4117ffe84148	postgres    conf

The directory `postgres` contains the database files, so all projects, users, file editing history, etc.  The directory conf contains some secrets and log files.  There will also be one directory (like `be889c14-dc96-4538-989b-4117ffe84148`) for each project that is created.

## Upgrade


To get the newest image, do this (which will take some time):

    docker pull  sagemathinc/cocalc

Once done, you can delete and recreate your CoCalc container.  This will not delete any of your project or user data, which you confirmed above is in ~/cocalc.

    docker stop cocalc
    docker rm cocalc
    docker run --name=cocalc -d -v ~/cocalc:/projects -p 443:443 sagemathinc/cocalc

Now visit https://localhost to see your upgraded server.

## Obtain a letsencrypt certificate

The docker image has a script to ease configuration of letsencrypt
certificates, but it is not automated. Once you have a running
container:

 * you setup a letsencrypt account by doing (only once)
```
docker exec cocalc letsencrypt-cert setup [--test] <DOMAIN> <EMAIL>
```
The --test flag configures the account to use the staging letsencrypt
server which produces certificates signed by fake authority, but otoh
it doesn't have the small rate limit of the production letsencrypt.

 * you install or renew your certificate (has to be done periodically)
```
docker exec cocalc letsencrypt-cert renew
```

The last step could be automated.

In practice, certificates last for 90 days and if you gave a proper email address you will receive a reminder when the certificate is close to expire.

As it is configured, the last step won't do anything unless your certificate is less than 30 days from expiration, so it is safe to run that once or twice a day. You can use the host cron to repeat it -- the docker container doesn't run cron itself.

In order for this to work, you have to have port 80 exposed and
accessible directly through `<DOMAIN>`


## Build

This section is for CoCalc developers.

Build the image

    make build-full   # or make build

Run the image (to test)

    make run

How I pushed this

    docker tag smc:latest sagemathinc/cocalc
    docker login --username=sagemathinc
    docker push  sagemathinc/cocalc

Also to build at a specific commit.

    docker build --build-arg commit=121b564a6b08942849372b9ffdcdddd7194b3e89 -t smc .

## Links

* [CuCalc = CUDA + CoCalc Docker container](https://github.com/ktaletsk/CuCalc)
