# CoCalc Docker image

GitHub: https://github.com/sagemathinc/cocalc-docker

**Quickstart on a Linux server**

1. Make sure you have at least **25GB disk space free and Docker installed.**
2. Run

```sh
docker run --name=cocalc -d -v ~/cocalc:/projects -p 443:443 sagemathinc/cocalc
```
NOTE: There are also aarch64 images for Apple M1, and a "lite" version that is much smaller because
it doesn't come with Sage, Latex, etc.  See https://hub.docker.com/u/sagemathinc for a list of images.

3. Wait a few minutes for the image to pull, decompress and the container to start, then visit https://localhost.

For other operating systems and way more details, see below.  But a quick note, if you are using aarch64 (e.g., Apple Silicon or Rasberry Pi 64-bit), use `sagemathinc/cocalc-aarch64` instead of `sagemathinc/cocalc` for a native binary!

```sh
docker run --name=cocalc -d -v ~/cocalc:/projects -p 443:443 sagemathinc/cocalc-aarch64
```

If the above doesn't work due to something else already using port 443 or you wanting to serve cocalc on a different port, you could use `-p 4043:443` instead.  There is extensive Docker documentation online.  For example the following runs the lite version of cocalc-docker on an Apple M1 serving on port 7100:

```sh
 docker run --name=cocalc -d -v ~/cocalc:/projects -p 7100:443 sagemathinc/cocalc-lite-aarch64
 ```
 
## Connecting to https://localhost:...

The default cocalc-docker container of course has only a self-signed ssl certificate.  Browsers have cracked down more and more on allowing
connections to such servers.   Because cocalc-docker is serving on localhost, you can explicitly tell your browser to allow the connection.
Do a Google search for "chrome allow localhost https" to find out how; one result is https://communicode.io/allow-https-localhost-chrome/.

## What is this?

**Run CoCalc for free for a small group on your own server or laptop!**

This is a free open-source  multiuser CoCalc server that you can _**very easily**_ install on your own computer or server using Docker.  If you need something to install on a cluster of servers using Kubernetes, see [cocalc-kubernetes](https://github.com/sagemathinc/cocalc-kubernetes).

**LICENSE AND SUPPORT:**

- Much of this code is licensed [under the AGPL](https://en.wikipedia.org/wiki/Affero_General_Public_License) condition to the [commons clause](https://commonsclause.com/) exception. If you would instead like a business-friendly MIT license instead, please contact [help@cocalc.com](help@cocalc.com), and we will sell you a 1-year license for $999, which includes some support (you can pay more for significant support).  We **do** have several happy paying customers as of September 2020, and cocalc-docker is very popular.
- Join the [CoCalc Docker mailing list](https://groups.google.com/a/sagemath.com/group/cocalc-docker/subscribe) for news, updates and more.
- [CoCalc mailing list](https://groups.google.com/forum/?fromgroups#!forum/cocalc) for general community support.

**SECURITY STATUS:**

- This is _**not blatantly insecure**_ from outside attack: the database has a long random password, user accounts are separate, encrypted SSL communication is used by default, etc.
- That said, **a determined user with an account can easily access or change files of other users in the same container!** Open ports are exposed to users for reading/writing to project files, these can be used by authenticated users for accessing any other project's open files. Requests should only connect to the main hub process, which proxies traffic to the raw server with an auth key created by the project's secret key changing on every project startup, see [Issue 45](https://github.com/sagemathinc/cocalc-docker/issues/45). Also see the related issues for adding a user auth token to all requests required for each separate sub module, including JupyterLab server [Issue 46](https://github.com/sagemathinc/cocalc-docker/issues/46) and classical Jupyter in an iframe [Issue 47](https://github.com/sagemathinc/cocalc-docker/issues/47).
- There is no quota on project resource usage, so users could easily crash the server both intentionally or accidentally by running arbitrary code, and could also overflow the storage container by creating excessive files.
- Use this for personal use, behind a firewall, or with an account creation token, so that only other people you trust create accounts.  Don't make one of these publicly available with important data in it and no account creation token! See [issue 2031]( https://github.com/sagemathinc/cocalc/issues/2031).  Basically, use this only with people you trust.
- See the [open docker-related CoCalc issues](https://github.com/sagemathinc/cocalc/issues?q=is%3Aopen+is%3Aissue+label%3AA-docker).

## Instructions

Install Docker on your computer (e.g., `apt-get install docker.io` on Ubuntu).   Make sure you have at least **25GB disk space free**, then type:

    docker run --name=cocalc -d -v ~/cocalc:/projects -p 443:443 sagemathinc/cocalc

wait a few minutes for the image to pull, decompress and the container to start, then visit https://localhost.  (If you are using Microsoft Windows, instead open https://host.docker.internal/.) It is expected that you'll see a "Your connection is not private" warning, since you haven't set up a security certificate.  Click "Show advanced" and "Proceed to localhost (unsafe)".

NOTES:

- This Docker image only supports 64-bit Intel.  For ARM aarch64 (e.g., Apple Silicon) just replace sagemathinc/cocalc above by sagemathinc/cocalc-aarch64.

- If you get an error about the Docker daemon, instead run `sudo docker ...`.

- CoCalc will NOT work over insecure port 80.  A previous version of these directions suggested using -p 80:80 above and visiting http://localhost, [which will not work](https://github.com/sagemathinc/cocalc/issues/2000).

- If you are using Microsoft Windows, instead make a docker volume and use that for storage:
  ```
  docker volume create cocalc-volume
  docker run --name=cocalc -d -v cocalc-volume:/projects -p 443:443 sagemathinc/cocalc
  ```


- IMPORTANT: If you are deploying CoCalc for use over the web (so not just on localhost), it is probably necessary to obtain a **valid security certificate** instead of using the self-signed unsafe one that is in your Docker container.    See [this discussion](https://groups.google.com/forum/?utm_medium=email&utm_source=footer#!msg/cocalc/7QO1hJQQGYY/Zsev1G72AAAJ).

- If you are using Ubuntu as a host and would like the CoCalc instance to use your host's time and timezone, you can amend the run command as follows, which will use your host's timezone and localtime files inside the container:
  ```
  docker run --name=cocalc -d -v ~/cocalc:/projects -v "/etc/timezone:/etc/timezone" -v "/etc/localtime:/etc/localtime" -p 443:443 sagemathinc/cocalc
  ```

The above command will first download the image, then start CoCalc, storing your data in the directory `~/cocalc` on your computer. If you want to store your worksheets and edit history elsewhere, change `~/cocalc` to something else.  Once your local CoCalc is running, open your web browser to https://localhost.  (If you are using Microsoft Windows, instead open https://host.docker.internal/.)

The docker container is called `cocalc` and you can refer to the container and use commands like:

```
$ docker stop cocalc
$ docker start cocalc
```

You can watch the logs:

```
$ docker logs cocalc -f
```

However, these logs sometimes don't work.  In that case get a bash shell in the terminal and look at the logs using tail:

```
$ docker exec -it cocalc bash
$ tail -f /var/log/hub.log
```

### Using a custom base path

If you want cocalc\-docker to serve everything with a custom base path, e.g., at `https://example.com/my/base/path` then you have to do two things.

#### (1) Set the BASE\_PATH environment variable:

```sh
docker run -e BASE_PATH=/my/base/path --name=cocalc -d -v ~/cocalc:/projects -p 443:443 sagemathinc/cocalc
```

This sets the base path correctly for most of CoCalc, but not for everything, unfortunately. 

#### \(2\) Rebuild the [next.js](https://nextjs.org/) package

The next package in CoCalc itself is the only thing that hardcodes the basepath.  You have to rebuild it exactly once with the `BASE_PATH` environment variable set, as follows:

```sh
~/cocalc-docker/aarch64$ docker run -e BASE_PATH=/my/base/path --name=cocalc -d -v ~/cocalc:/projects -p 443:443 sagemathinc/cocalc-aarch64
034cf17482a467537addd8ef8db0406277a7f76789eac4b03e0535d8e0d9ccfc
~/cocalc-docker/aarch64$ docker exec -it cocalc bash
root@034cf17482a4:/# umask 022
root@034cf17482a4:/# cd /cocalc/src/packages/next
root@034cf17482a4:/cocalc/src/packages/next# echo $BASE_PATH
/my/base/path
root@034cf17482a4:/cocalc/src/packages/next# time npm run build
real    2m12.900s
# Expect this to take a LONG TIME, e.g., up to 10 minutes, though it
# just took 2 minutes on a fast server for me.

Now exit the docker container and restart it to switch to the new version:

~/cocalc-docker/aarch64$ docker stop cocalc; docker start cocalc
```

Now visit: https://localhost:443/my/base/path/ and it should fully work.

We do much of the development of CoCalc itself on https://cocalc.com using a `BASE_PATH`.  So fortunately `BASE_PATH` functionality does get used frequently.

### Completely disable idle timeout

Projects will stop by default if they are idle for 30 minutes.  Admins can manually increase this for any project.  If you want to completely disable the idle timeout functionality, set the `COCALC_NO_IDLE_TIMEOUT` environment variable.  Note that the user interface will still show an idle timeout -- it's just that it will have no impact.

```sh
docker run -e COCALC_NO_IDLE_TIMEOUT=yes --name=cocalc -d -v ~/cocalc:/projects -p 443:443 sagemathinc/cocalc
```

### Installing behind an Nginx Reverse Proxy

If you're running multiple sites from a single server using an Nginx reverse proxy, a setup like the following could be useful.

Instead of mapping port 443 on the container to 443 on the host, map 443 on the container to an arbitray unused port on the host, e.g. 9090:

```sh
docker run --name=cocalc -d -v ~/cocalc:/projects -p 9090:443 sagemathinc/cocalc
```

In your nginx `sites-available` folder, create a file like the following called e.g. `mycocalc`:

```
map $http_upgrade $connection_upgrade {
        default upgrade;
        ''      close;
}

server {
    listen 443 ssl;
    server_name             mycocalc.com;
        
    #These need to be obtained independently for example from https://letsencrypt.org/, by running "certbot certonly" on the docker host after DNS is setup
    ssl_certificate         /etc/letsencrypt/live/mycocalc.com/fullchain.pem;
    ssl_certificate_key     /etc/letsencrypt/live/mycocalc.com/privkey.pem;

    location / {
        # push traffic through the proxy to the port you mapped above, in this case 9090, on the localhost:
        proxy_pass https://localhost:9090;
        
        # this enables proxying for websockets, which cocalc uses extensively:
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_set_header Host $host;
    }
}
```

And soft-link it to your `sites-enabled` folder, e.g. `sudo ln -s /etc/nginx/sites-available/mycocalc /etc/nginx/sites-enabled/mycocalc`

If you're using certbot and letsencrypt, you can then get a certificate for your domain using something like `sudo certbot --nginx` and selecting "mycocalc.com", which will automatically set up an ssl cert and modify your nginx server file.

### MacOS (running on localhost)

#### Clock skew

I have tested a lot in November 2021, and did NOT have any problems with clock skew with Docker Desktop, so this appears to be fixed.   If not -- It is **critical** that the Docker container have the correct time, since CoCalc assumes that the server has the correct time.  On a laptop running Docker under MacOS, the clock may get messed up any time you suspend/resume your laptop.  This workaround might work for you: https://github.com/arunvelsriram/docker-time-sync-agent/.

#### Apple Silicon M1 / Linux aarch64/arm64 is fully supported via a different image

I regularly post an Apple Silicon Aarch64 cocalc-docker image. This runs natively.  It should also work on other aarch64 Linux systems.

[https://hub.docker.com/r/sagemathinc/cocalc-aarch64](https://hub.docker.com/r/sagemathinc/cocalc-aarch64?ref=login)

#### Browser Issues with MacOS

Cocalc-docker by default uses a self signed certificate on localhost.

- **Firefox -- works fine:** With Firefox you can click through some warnings and use CoCalc-docker just fine.
- **Chrome -- does NOT work:** With Chrome, you can try to [use the workaround here](https://stackoverflow.com/questions/35531347/localhost-blocked-on-chrome-with-privacy-error), which involves visiting `chrome://flags/#allow-insecure-localhost` , but I've found that the websocket connection to the project is still blocked.
- **Safari -- works fine:** With current Safari, you can click through to "accept the risks", and it works really well.

### Chromebook

You can run CoCalc locally on your Chromebook as long as it supports Crostini Linux.

1. Install (Crostini) Linux support -- search for Linux in settings and enable.

2. In the Linux terminal, type
   ```
   sudo su

   apt-get update && apt-get upgrade && apt-get install tmux dpkg-dev
   ```


3. Install Docker [as here](https://docs.docker.com/install/linux/docker-ce/debian/#set-up-the-repository):
   ```
   sudo su

    apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common &&  \
   curl -fsSL https://download.docker.com/linux/debian/gpg |  apt-key add - && \
    apt-key fingerprint 0EBFCD88  && \
    add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/debian \
    $(lsb_release -cs) \
    stable" && \
    apt-get update  && apt-get install -y docker-ce
   ```


4. Install cocalc-docker:
   ```
   sudo docker run --name=cocalc -d -v /cocalc:/projects -p 443:443 -p 80:80 sagemathinc/cocalc
   ```

   Type `/sbin/ifconfig eth0|grep inet` in the terminal, and use whatever ip address is listed there -- e.g., for me it was https://100.115.92.198/

### SSH port forwarding

If you're running this docker image on a remote server and want to use ssh port forwarding to connect, type:

```
ssh -L 8080:localhost:443 username@remote_server
```

then open your web browser to https://localhost:8080

For **enhanced security**, make the container only listen on localhost:

```
docker stop cocalc
docker rm cocalc
docker run --name=cocalc -d -v ~/cocalc:/projects -p  127.0.0.1:443:443 sagemathinc/cocalc
```

Then the **only way** to access your CoCalc server is to type the following on your local computer:

    ssh -L 8080:localhost:443 username@remote_server

and open your web browser to https://localhost:8080

### SSH into a project

Instead of doing:

```
docker run --name=cocalc -d -v ~/cocalc:/projects -p 443:443 sagemathinc/cocalc
```

do this:

```
docker run --name=cocalc -d -v ~/cocalc:/projects -p 443:443 -p <your ip address>:2222:22  sagemathinc/cocalc
```

Then you can do:

```
ssh projectid@<your ip address> -p 2222
```

Note that `project_id` is the hex id string for the project *without hyphens*. One way to show project id in this format is to open a .term file in the project and run this command: (This only works in CoCalc in Docker; USER is set differently in production CoCalc.)

```
echo $USER
```

To use SSH key authentication with the Docker container, have your private key file in the usual place in the host computer, for example `~/.ssh/.id_cocalc`, and copy the matching public key into your project's home directory. For example, you could do the following in a .term in your project:

```
cd
mkdir .ssh
chmod 700 .ssh
vi .ssh/authorized_keys
... paste in contents of ~/.ssh/id_cocalc.pub from host computer ...
chmod 600 .ssh/authorized_keys
```

### Make a user an admin

Get a bash shell insider the container, then connect to the database and make a user (me!) an admin as follows:

```sh
$ sudo docker exec -it cocalc bash
root@17fecb49c5c2:/# cd /cocalc/src/scripts
root@17fecb49c5c2:/cocalc/src/scripts# ./make-user-admin wstein@gmail.com
UPDATE 1
```

Obviously, you should really make the user you created (with its email address) an admin, not me!Refresh your browser, and then you should see an extra admin tab and the top of your browser window; you can also open any project by directly visiting its URL, and change the idle timeout and always running settings.  In the Admin tab you can search for users, impersonate any user, ban users, configure dozens of things about CoCalc, send a notification that all signed in users see, and more.  One thing admin users can't do is get a root shell -- for that you have to use `sudo docker exec -it cocalc bash` (of course, CoCalc is just Ubuntu linux, so you could make it so a specific project can become root via sudo).

Note that the make-user-admin script is in /cocalc/src/scripts.  Take a look at it:

```sh
root@17fecb49c5c2:/cocalc/src/scripts# more ./make-user-admin
...
echo "update accounts set groups='{admin}' where email_address='$1'" | psql
```

As you can see, aside from some error checking, the entire script is just a 1-line PostgreSQL query.If you know basic SQL, you can  very easily do all kinds of interesting things.If you type `psql` as root, you'll get the PostgreSQL shell connected to the database for CoCalc.Type `\d` to see the tables, and `\d tablename` for more about a particular table.  For example,typing `\d accounts` shows all the fields in the accounts table, and groups is one of them.Here's [where in the source code](https://github.com/sagemathinc/cocalc/tree/master/src/smc-util/db-schema) ofCoCalc itself all of these database tables are defined.    In any case, being aware of all this can be very helpfulif you want to do some batch action, e.g., :

- delete all accounts that are old or inactive
- query to get the status of projects or accounts

### Make a _project_ have sudo access

You can also make it so that running `sudo su` in a CoCalc terminal allows a project to gain root access.  First as above, from outside of CoCalc, do`docker exec -it cocalc bash`, then type `visudo`:

```
$ docker exec -it cocalc bash
root@931045eda11f:/# visudo
```

Then run this echo command, but replace `0630f773c01847e79c0863c0118fe0de` by the project id with all dashes removed:

```
echo '0630f773c01847e79c0863c0118fe0de ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
```

Alternatively, you can get the username by typing `whoami` in a terminal from the project:

```
~$ whoami
0630f773c01847e79c0863c0118fe0de
```

After the above echo command, go to a terminal in your project and try `sudo su`:

```
~$ sudo su
root@121119037fd4:/projects/0630f773-c018-47e7-9c08-63c0118fe0de# ls /root
run.py
```

Bam, you're root!

NOTE: A project having sudo access is completely unrelated to a user in CoCAlc being an admin.  Neither implies the the other.

NOTE: You can also use `visudo` to edit the file (which is better), or `EDITOR=emacs visudo` to edit it using emacs.

WARNING: Obviously having a user able to run as root in a Docker container introduces additional security issues.

### Reset a user's password

Sign in as a user that is an admin (see the previous section above).  Click on the Admin tab at the top, search for the user, and then click the "Password" toggle, and click "Request Password Reset Link...".

This does NOT set the password.  It just makes a password reset link, which you send your user via some communications channel that works.  You may need this because:

- You do not have email setup.  It is possible to setup Sendgrid so your cocalc-docker image sends out email, but we haven't documented that yet...
- You have email setup, but it sometimes fails for users with aggressive spam filtering.

### Registration Tokens

After making your main account an admin as above, search for " Registration Tokens" in the Admin tab.  Create one or more tokens and share them with people who you want to use your server.  Nobody else will be able to make an account.

### Public Sharing of Files

By default users are NOT allowed to share files publicly, and the server at your\_server/share is disabled.  You can enable the share server and public file sharing in Admin --&gt; Site Settings --&gt; "Allow public file sharing".

### Anonymous Accounts

Similar to public file sharing, users are not allowed to make an account without entering an email address and password.   You can further restrict users by requiring a registration token or via disabling "Allow email signup" in Admin --&gt; Site Settings.  On the other hand, you can allow anybody to use your server _**without even creating an account**_ by going to Admin --&gt; Site Settings --&gt; "Allow anonymous signup".   You probably don't want to do this.

### Terminal Height

If `docker exec -it cocalc bash` doesn't seem to give you the right terminal height, e.g. content is only displayed in the uppper part of the terminal, this workaround may help when launching bash:

```
docker exec -e COLUMNS="`tput cols`" -e LINES="`tput lines`" -it cocalc bash
```

More information on this issue is in [moby issue 33794](https://github.com/moby/moby/issues/33794).

### Installation for SELinux (Fedora, etc.)

In order to build and run CoCalc on an SELinux box, first set SELinux to permissive:

```
$ setenforce 0
```

<Install cocalc>

Tell docker and SELinux to "play nicely":

```
$ chcon -Rt svirt_sandbox_file_t cocalc
```

return SELinux to enabled:

```
$ setenforce 1
```

-- via [discussion](https://groups.google.com/forum/#!msg/cocalc/nhtbraq1_X4/QTlBy3opBAAJ)

## Your data

If you started the container as above, there will be a directory ~/cocalc on your host computer that contains **all** data and files related to your projects and users -- go ahead and verify that it is there before upgrading. It might look like this:

```
Williams-MacBook-Pro:~ wstein$ ls cocalc
be889c14-dc96-4538-989b-4117ffe84148	postgres    conf
```

The directory `postgres` contains the database files, so all projects, users, file editing history, etc. The directory conf contains some secrets and log files. There will also be one directory (like `be889c14-dc96-4538-989b-4117ffe84148`) for each project that is created.

## Upgrade

New images are released regularly, as you can see [on the SageMath, Inc. Dockerhub page](https://hub.docker.com/u/sagemathinc).

To get the newest image, do this (which will take some time):

```
docker pull  sagemathinc/cocalc
```

Once done, you can delete and recreate your CoCalc container: (This will not delete any of your project or user data, which you confirmed above is in ~/cocalc.)

    docker stop cocalc
    docker rm cocalc
    docker run --name=cocalc -d -v ~/cocalc:/projects -p 443:443 sagemathinc/cocalc

Now visit https://localhost to see your upgraded server.

#### Upgrade just the CoCalc source code (potentially tricky)

Instead of upgrading the Docker image, you could upgrade the source code of cocalc to the latest master version (or any other commit or branch) as follows.

First become root in your container: `docker exec -it cocalc bash`, then:

```sh
root@...:~# umask 022
root@...:~# cd /cocalc/src
root@...:/cocalc/src# git pull
root@...:/cocalc/src# npm run make
```

This should take about 15 minutes.  It could randomly fail if some npm package is temporarily not available; if that happens, try again.   Once it finishes successfully, stop your container, then start it again.   Upgrading this way does not upgrade any system-wide Ubuntu packages or configuration, so it might result in a broken Docker container.  In that case, your data should be fine, and you can upgrade as described in the section above.

## Adding custom software to your CoCalc instance

The CoCalc Docker images at Docker Hub contain a subset of all the software in at [cocalc.com](https://cocalc.com). At present, the images are about 12 GB while the cloud service has hundreds of GB of packages and libraries.

Suppose you'd like to add software to your local CoCalc instance after installing and starting the Docker container. Here's an example of how to add an install of [texlive-full](https://packages.ubuntu.com/bionic/texlive-full), in case you need more than the minimal `texlive` installation in the published image:

The Docker image is Ubuntu 18.04. You can do

    sudo docker exec -it [container name] bash

to become root in the container, then do

    apt-get install texlive-full

to install the package.

Note that the `texlive-full` package is over 3 GB. So you will need the additional disk space to install it, and it could take several minutes to over an hour to install, depending on your connection to the internet and the speed of your computer.

Additional notes:

- **Be sure to type `umask 022` first** before you install software if you are using a method other than `apt-get`. This step is needed to ensure that permissions are set properly. The default umask is 007. If you use `pip3` or `pip2` without setting the umask to 022, the package gets installed, but it is not *visible* to normal users as a result.
- Most instructions for adding packages to Ubuntu 18.04 should work for CoCalc-Docker, for example `pip install` for Python 2 packages, and `pip3 install` for Python 3 packages.
- Whenever you upgrade your CoCalc image from Docker Hub as described in **Upgrade** above, you will need to repeat the above steps.

## User-contributed scripts

- See the [contrib](./contrib) subdirectory here for  scripts contributing by people that are running their own cocalc-docker servers.  For example, there is a Python script for removing old accounts and old or deleted projects.

## Troubleshooting

- [A short guide](./TROUBLESHOOTING.md)

## Build

This section is for CoCalc developers.

Build the image:

```
make build-full   # or make build
```

Run the image (to test):

```
make run
```

How I pushed this:

```
docker tag smc:latest sagemathinc/cocalc
docker login --username=sagemathinc
docker push  sagemathinc/cocalc
```

Also to build at a specific commit:

```
docker build --build-arg commit=121b564a6b08942849372b9ffdcdddd7194b3e89 -t smc .
```

## Adding Tensorflow-GPU support

This section assuming that your docker host has a GPUs and the nvidia-docker2 runtime is installed properly. For more information please see the [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-docker) project.

Test of the docker with GPUs support should give a similar output:

```
(base) [root@gput401 cocalc-docker]# docker run --runtime=nvidia -e NVIDIA_VISIBLE_DEVICES=all --rm nvidia/cuda:latest nvidia-smi
Tue Jun 16 17:52:16 2020       
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 440.64.00    Driver Version: 440.64.00    CUDA Version: 10.2     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  Tesla T4            Off  | 00000000:00:06.0 Off |                    0 |
| N/A   31C    P0    16W /  70W |      0MiB / 15109MiB |      0%      Default |
+-------------------------------+----------------------+----------------------+
                                                                               
+-----------------------------------------------------------------------------+
| Processes:                                                       GPU Memory |
|  GPU       PID   Type   Process name                             Usage      |
|=============================================================================|
|  No running processes found                                                 |
+-----------------------------------------------------------------------------+
```

If the test running w/o problems, you can start to rebuild your own cocalc docker image with tensorflow support:

```
cp  Dockerfile Dockerfile.gpu
```

Simply change first line in the Dockerfile.gpu

```
#FROM ubuntu:18.04
FROM tensorflow/tensorflow:latest-gpu
```

Rebuild your image:

```
docker build  -t cocalc-gpu -f Dockerfile.gpu .
```

Run it:

```
docker run -it --runtime=nvidia -e NVIDIA_VISIBLE_DEVICES=all   --name=cocalc-gpu -d -v ~/cocalc_test:/projects -p 443:443 -p 0.0.0.0:2222:22  --rm  cocalc-gpu  bash
```

## Links

- [CuCalc = CUDA + CoCalc Docker container](https://github.com/ktaletsk/CuCalc)
- [NCT = NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-docker)

