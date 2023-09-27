# Using ssh to connect to cocalc\-docker running in "personal" mode

There is a minimal version of cocalc\-docker that is built to run in a personal mode.  Everything runs as a single non\-root user, so it can run in an extremely constrained and limited Docker environment.

Personal cocalc\-docker does support ssh access. The ssh server is not listening on port 22, since it runs as a non\-root user.  Instead **ssh is listening on port** **2222**, and the sshd daemon is running as a normal process.  You an see it if you do `ps -ax |grep sshd` in any CoCalc project on your personal server, and of course if you were to kill that process, ssh into the container would stop working.

To be able to use ssh, you need to create the container with port 2222 exposed as illustrated in the [README.md](http://README.md). 

You should then edit the file /home/user/.ssh/authorized\_keys to container the ssh public key for the account that you want to be able to use to ssh into your container.  For example, you could just create a cocalc account, open a terminal, cd to /home/user, and do this, but with your ssh key \(or use vi or `open .ssh/authorized_keys` \):

```sh
/home/user$ echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA1bwpB7b7TVIexZxW003FCbDqzyFurSwZlljmT7sWzo wstein@Williams-Mac-Studio.local" > .ssh/authorized_keys
```

Alternatively, you can use any other method you want to copy `/home/user/.ssh/authorized_keys` into your Docker container.

Now you can ssh into your container:

```sh
wstein@studio ~ % ssh user@localhost -p 5222
user@cd8586285b41:~$ ls /
bin  boot  dev  etc  home  lib  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
```

Note the port option; what it is depends on how you ran the Docker container, and 5222 is just the example I happened to use in the README.

NOTE: If you want to rsync files to your container, you also have to explicilty specify a port, and that is done in a slightly different way than with ssh:

```sh
rsync -e 'ssh -p 2222' ...
```

