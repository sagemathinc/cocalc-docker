# **How to run your own CoCalc\-Docker server on** https://CoCalc.com

It is now possible to run your own instance of cocalc\-docker for personal use on [https://cocalc.com.](https://cocalc.com)  This is a way to use Jupyter notebooks, LaTeX, VS Code Server, JupyterLab, and much more. It has many advantages involving performance and privacy over just using https://cocalc.com directly:

- You can run the server geographically close to yourself, which makes it much faster
- Your data is not backed up as part of the rest of cocalc in any way, which may be important for some use cases involving privacy or just storing large amounts of data.
- You can use massive amounts of compute resources and disk space, with high performance
- At the same time, support is still available.
- Cocalc\-docker fully supports using all of CoCalc's own editors, in addition to JupyterLab and VS Code.

The instructions below are mainly oriented around setting this up for a single user, though you can also follow these directions for use with a **small trusted group** of users.

This guide assumes basic familiarity with Docker \([tutorial](https://docker-curriculum.com/)\) and CoCalc \([docs](https://doc.cocalc.com/)\), and has some overlap with the [cocalc\-docker](https://github.com/sagemathinc/cocalc-docker) docs.

**COSTS:** CoCalc charges by the second for compute servers. The rates are clearly stated and depend on the resources you create.  Cocalc\-Docker itself is not free and open source, and business use requires a license.  Please contact us at [help@cocalc.com](mailto:help@cocalc.com).  However, don't hesitate to _**try out this guide**_ and make sure that cocalc\-docker works for you before contacting us about a license. 

# Summary

This document provides a step\-by\-step guide on how to set up and run your own instance of CoCalc for personal use on a CoCalc compute server hosted by https://cocalc.com.  

Key steps covered in this guide include:

- Creating a compute server on https://cocalc.com 
- Installing CoCalc\-Docker on your compute server.
- Setting up and creating a new account and setting it as an admin
- Optional: giving all projects root privileges
- Setting up a registration token
- Installing Docker into cocalc\-docker 
- Adjusting compute power and disk space as needed
- Creating backups 
- Upgrading Ubuntu software and CoCalc 

Considerations around lifecycle, such as turning off or suspending your CoCalc\-Docker server to save money, are also discussed. Note that running out of disk space or needing more compute power are issues that can be easily resolved. 

Bear in mind that currently you will need to setup your own backups to ensure you won't lose your data. 

# Create a compute server

Create a compute server on Google Cloud. Make sure it has at least:

- 8GB RAM
- 35GB disk space

![](images/paste-0.16216894876939447)

- Setup a "Custom Domain Name with SSL" by checking the box near the bottom
- Where it says "Fast Data Directories" type `cocalc-docker` 

![](images/paste-0.7481474241254178)

NOTES:

- Choose region that is geographically close to you. It will make cocalc\-docker feel MUCH faster for you.
- A spot instance is usually fine, though if you want your server to be always available, right now you have to choose a standard instance, since automatic restart isn't implemented yet.  Spot instances are sometimes killed when capacity is low, so you have to be OK with that; however, the price is amazing!
- If the instance type starts with `t2a-` it's arm64 instead of x86\_64. This is fully supported.

# Install [cocalc\-docker](https://github.com/sagemathinc/cocalc-docker)

Open a terminal in your cocalc project, and select the compute server, so
you get a terminal running on the compute server, with a prompt like `🖥️ (compute-server-42) ~$` Paste in the following code:

```sh
time docker run \
   --name=cocalc-docker \
   -d --network host \
   --restart always \
   --privileged \
   -v /var/run/docker.sock:/var/run/docker.sock \
   -v /data/cocalc-docker:/projects \
   --mount type=bind,source=/data,target=/data,bind-propagation=rshared \
   --mount type=bind,source=/home,target=/home,bind-propagation=rshared \
   sagemathinc/cocalc-docker
```

It should take about 5\-15 minutes to download about 23GB from Dockerhub. This download is free since it is incoming data.

*NOTE:* If you selected a compute server with a GPU, you need to also add `--gpus all` to the command above.  Also, none of the software pre-installed in CoCalc docker supports GPU's in any interesting way, so you may want to [build a custom cocalc-docker image](https://github.com/sagemathinc/cocalc-docker#adding-tensorflow-gpu-or-pytorch-gpu-support). 


The above command runs the `sagmeathinc/cocalc-docker` container in daemon mode with the same network as the machine \(so if you open up web servers they are visible\), in privileged mode so that it is possible to do things like use advanced filesystems, and with the ability to run Dockeer from within the container. It also mounts som external filesystems.

![](images/paste-0.8019523521035041)

# Setup

## Create your new account

Connect to https://name.cocalc.cloud, where name is what you chose in step 1,
and create a new account. Use a good password.

![](images/paste-0.9150035386462037)

## Make your new account an admin

In your shell back on https://cocalc.com, with the `🖥️ (compute-server-42) ~$` prompt, type

```sh
docker exec -it cocalc-docker bash
```

to get a root shell inside your cocalc-docker instance. Make your new user an admin, replacing `wstein@gmail.com` with the email address you used:

```sh
/cocalc/src/scripts/make-user-admin wstein@gmail.com
```

### Optional: make all accounts have root privileges

Depending on how you want to use cocalc-docker, you may want to make it so all projects have the ability to run any command as root. To do this, type

```sh
visudo
```

then paste this at the bottom:

```sh
ALL ALL=(ALL) NOPASSWD: ALL
```

This is ideal if you will be the only person using this cocalc-docker server, since it makes it very easy to install software, etc.

**Disclaimer:** _While providing access to root privileges can be useful, it's also risky from a security perspective.  These directions mainly assume you want to setup a cocalc\-docker instance for use by a very small number of highly trusted users for research applications._

## Setup a registration token

You made your account on https://name.cocalc.cloud an admin, so there will be a new Admin tab at the top. You can configure a massive amount here to customize your installation. **One critical thing to configure ASAP is a registration token, so that no random people make accounts on your server!**
Just click on "Registration Tokens", then Add, leave the defaults as is, and click save. Now, without knowing that long random code, nobody can make another account on your server.

## Install Docker into cocalc-docker

It's convenient to be able to use Docker from within a cocalc-docker project to run other containers.  
Since Docker itself isn't installed in cocalc-docker, you have to install it, as follows. First get a root
shell inside your cocalc-docker container:

```sh
🖥️ (compute-server-42) ~$ docker exec -it cocalc-docker bash
root@prod-42:/# 
```

Then paste the following, which installs the latest official version of Docker, and should take less than a minute:

```sh
   apt-get update -y \
&& apt-get install -y ca-certificates curl gnupg \
&& install -m 0755 -d /etc/apt/keyrings \
&& curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
&& chmod a+r /etc/apt/keyrings/docker.gpg \
&& echo \
"deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
tee /etc/apt/sources.list.d/docker.list > /dev/null \
&& apt-get update -y \
&& apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

Once you do this, if you setup sudo above, then any cocalc project on your server can use Docker by typing `sudo docker ...` .  Note that this Docker is the same Docker that is running cocalc\-docker itself, so be careful.

# Lifecycle: Turning Off or Suspending

To save money, at any point you can just turn off your compute server, so you only pay for the disk space that it uses.  You can see exactly how much this will cost by hovering your mouse over the "Stop" button in the compute server panel:

![](images/paste-0.9688266919881261)

Click the "Off" button in the compute server panel.  When you turn your server back on, you should find cocal\-docker is running again automatically, because of the `--restart always`  option above when you created the container.

When the container turns back on, it will have a _**different ip address**_. However, https://cocalc.com automatically updates the DNS, so https://name.cocalc.cloud immediately continues to work.

You can also suspend your cocalc\-docker instance to RAM, by clicking "Suspend". This costs more, because the contents of memory must also be stored, but when you restore from suspend, the server will be configured exactly the way you left it, which is very convenient and can save you time.  Note that how long this takes, costs, and whether it works at all \(it's variable\) depends on how much RAM you allocated to your compute server.   

![](images/paste-0.616857263710451)

# Increasing Disk Space

Just click "Edit" in the compute server panel, scroll down to your disk, and increase the size.  In a few seconds, the disk in the compute server will be enlarged.  This works fine while the compute server is running, and no restart is needed.

![](images/paste-0.14268845680977904)

# Increasing Compute Power

Just stop your compute server, click "Edit", and change the Machine Type.  E.g., if you want 48 vCPUS, search for cpu`:48`  and choose an option. You can then run your compute server for a while with that instance.  When you're done, switch back.

![](images/paste-0.5977909484072013)

# Making Backups

**DISCLAIMER:** _This section is under construction._

You can use any standard backup strategy that supports Linux, and there are dozens of mature options out there.

One choice for offsite backups is https://www.backblaze.com/.  You can create an account, set up backblaze, and have backups of all your data from this cocalc\-docker instance.  The backups are yours, and are outside of https://cocalc.com, so you can recover no matter what happens.

The key points:

- backing up the directory `/data/cocalc-docker` is sufficient to backup all the data in cocalc projects and all configuration \(e.g., user accounts, projects, etc.\) 
- cocalc charges for outgoing network usage, so backing up just the important data is a good idea.

NOTE: We have NOT yet added a one\-click option to make automated disk level backups of the compute server.   Even once cocalc adds automated disk\-level backups, you should consider seting up your own backups, so that you can be confident that you won't lose your data.

# Upgrades

## Ubuntu

It's a good practice to periodically update the Ubuntu software that's installed.
As root in the cocalc\-docker container:

```sh
apt-get update; apt-get upgrade
```

## Option: recreate the Docker image

On option is to delete the docker container via

```sh
docker stop cocalc-docker
docker rm cocalc-docker
```

then just paste in the command from section 2 above.  
Your user data and database is not stored in the
cocalc-docker container, so that stays unchanged.
This is a robust way to upgrade, but there is one 
very significant drawback, which is that any customizations
you've made to what software is installed systemwide 
must be made again. 

## Option: rebuild cocalc from source

You can easily pull and build any version of CoCalc and
run it in your cocalc-docker container.  To get the 
latest version, 

```sh
🖥️ (compute-server-42) ~$ docker exec -it cocalc-docker bash
root@prod-42:/# umask 022
root@prod-42:/# cd /cocalc/src/
root@prod-42:/cocalc/src# git pull
root@prod-42:/cocalc/src# pnpm build
root@prod-42:/cocalc/src# cd /root; python -c "import run; run.start_hub()"
```

The source code is in `/cocalc/src`.

The line `git pull` grabs the latest master branch of CoCalc.  Using git you can grab any branch or particular version of cocalc this way.  

The command `pnpm build` downloads any new or modified dependencies and compiles
and bundles all of the code.  The build should take 5-10 minutes, and will result 
in a production build of all of CoCalc.   During the build, it is normal for
https://name.cocalc.cloud to feel potentially broken, since you're changing files out
from under it.

The line `cd /root; python -c "import run; run.start_hub()"` restarts the CoCalc server.
At this point it is a good idea to refresh your browser pointing at https://name.cocalc.cloud.
Alternatively, you can do a full restart of cocalc-docker via

```sh
🖥️ (compute-server-42) ~$ docker restart cocalc-docker
```

