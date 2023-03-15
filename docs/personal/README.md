# Personal Version of CoCalc\-Docker

There is a minimal version of cocalc\-docker that is built to run in a "personal mode".  In this mode, **absolutely everything in the container runs as a single non\-root user named** **`user,`** so this can be run in an extremely constrained and limited Docker environment.  But note of course that any one user can see all other users or kill all processes.

You can build an updated version of cocalc\-personal yourself using the dockerfile in this repo, which is [Dockerfile\-personal](../../Dockerfile-personal).

We also sometimes build updated images using the scripts [here](../../aarch64-personal) and [here](../../x86_64-personal/) and you can run them as follows:

```sh
docker run --name=cocalc-personal-test -d -p 127.0.0.1:5123:5000 -p 127.0.0.1:5222:2222 -v ~/cocalc-personal:/home/user  sagemathinc/cocalc-personal-aarch64 
```

or for x86:

```sh
docker run --name=cocalc-personal-test -d -p 127.0.0.1:5123:5000 -p 127.0.0.1:5222:2222 -v ~/cocalc-personal:/home/user sagemathinc/cocalc-personal
```

With the above on localhost only you can connect to cocalc via http://localhost:5123 and you can ssh in via port 5222.  You can't directly connect from any external machine, which is a good approach for something that is not designed to be secure for multiple users at once. 
