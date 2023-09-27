# Personal Version of CoCalc\-Docker

There is a minimal version of cocalc\-docker that is built to run in a "personal mode", with no account authentication \(!\).  In this mode, **absolutely everything in the container runs as a single non\-root user named** **`user,`** so this can be run in an extremely constrained and limited Docker environment.  But note of course that any one user can see all other users or kill all processes.

You can create an account in the container, but **you don't have to and the password doesn't matter.**   

You can build an updated version of cocalc\-personal yourself using the dockerfile in this repo, which is [Dockerfile\-personal](../../Dockerfile-personal).

We also sometimes build updated images using the scripts [here](../../aarch64-personal) and [here](../../x86_64-personal/) and you can run them as follows, with data persisting to your home directory in `~/cocalc-personal`:

```sh
docker run --name=cocalc-personal-test -d -p 127.0.0.1:5123:5000 -p 127.0.0.1:5222:2222 -v ~/cocalc-personal:/home/user/cocalc/src/data sagemathinc/cocalc-v2-personal
```

or for AARCH 64 \(e.g., Apple Silicon\):

```sh
docker run --name=cocalc-personal-test -d -p 127.0.0.1:5123:5000 -p 127.0.0.1:5222:2222 -v ~/cocalc-personal:/home/user/cocalc/src/data  sagemathinc/cocalc-v2-personal-aarch64 
```

With the above on localhost only you can connect to cocalc via http://localhost:5123 and you can also [ssh in via port 5222 if you add your public key to /home/user/.ssh/authorized\_keys](./ssh.md).  You can't directly connect from any external machine, which is a good approach for something that is not designed to be secure for multiple users at once. 

If you open http://localhost:5123/projects even without creating an account, you'll be able to immediately start making cocalc projects and using them.  

Note that this is a very minimal installation, and if you want to use Jupyter, Latex, etc., you'll need to install them yourself into the container.  Just copy what is done from the main [Dockerfile](../../Dockerfile).

