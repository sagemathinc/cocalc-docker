# Some troubleshooting steps that may be useful

UPDATED: April 19, 2022

This may be of use in understanding how cocalc-docker works.

## Projects

Each project has several logfiles.

- The overall project server has a logfile located in `~/.smc/logs/log`.

- The Sage server has a logfile in `~/.smc/sage_server/sage_server.log`, which may be relevant is you are using Sage worksheets.

- If you use Jupyter classic mode, then there are log files in `~/.smc/jupyter`

## The Hub

The hub is a node.js process that every web browser connects to. It communicates with the PostgreSQL database, starts and stop projects, and proxies traffic between browsers and projects.

You can find the process via `pgrep -af cocalc-hub-server`:

```sh
root@367b9eb05898> pgrep -af cocalc-hub-server
4717 npm exec cocalc-hub-server --websocket-server --proxy-server --share-server --host=0.0.0.0 --https-key=/projects/conf/cert/key.pem --https-cert=/projects/conf/cert/cert.pem         
4729 node /cocalc/src/smc-hub/node_modules/.bin/cocalc-hub-server --websocket-server --proxy-server --share-server --host=0.0.0.0 --https-key=/projects/conf/cert/key.pem --https-cert=/projects/conf/cert/cert.pem
```

If you kill the process, you can start it again running in the foreground as follows, which may be useful for debugging:

```sh
your-server...> sudo docker exec -it cocalc bash
root@00f82bad6a5c:/# cd /cocalc/src/packages/hub
root@00f82bad6a5c:/cocalc/src/packages/hub# pkill -f cocalc-hub-server
root@00f82bad6a5c:/cocalc/src/packages/hub# ps ax |grep node
    131 pts/0    S+     0:00 grep --color=auto node
root@00f82bad6a5c:/cocalc/src/packages/hub# npm run  hub-docker-prod
> @cocalc/hub@1.58.2 hub-docker-prod
> COCALC_DOCKER=true DEBUG='cocalc:*,-cocalc:silly:*',$DEBUG NODE_OPTIONS=--max_old_space_size=8000 NODE_ENV=production PROJECTS=/projects/[project_id] PORT=443 NODE_OPTIONS=--enable-source-maps npx cocalc-hub-server --mode=multi-user  --all --hostname=0.0.0.0 --https-key=/projects/conf/cert/key.pem --https-cert=/projects/conf/cert/cert.pem
***
Logging to "/var/log/hub/log" via the debug module
with  DEBUG='cocalc:*,-cocalc:silly:*,'.
Use   DEBUG_FILE='path' and DEBUG_CONSOLE=[yes|no] to override.
Using DEBUG='cocalc:*,-cocalc:silly:*' to control log levels.
***
body-parser deprecated bodyParser: use individual json/urlencoded middlewares ...
[...]
Warning: connect.session() MemoryStore is not
designed for a production environment, as it will leak
memory, and will not scale past a single process.
...
^Z  (that means I hit control+z)
[1]+  Stopped                 npm run hub-docker-prod
root@00f82bad6a5c:/cocalc/src/packages/hub# bg
[1]+ npm run hub-docker-prod &
root@00f82bad6a5c:/cocalc/src/packages/hub# ls -l /var/log/hub/
total 200
-rw------- 1 root root   1129 Apr 20 00:00 err
-rw------- 1 root root 195388 Apr 20 00:06 log
-rw------- 1 root root    382 Apr 20 00:00 out
```

On successful startup, the file `/varlog/hub/log` will have contents that ends something like this: 

```sh
2022-04-20T00:03:10.617Z:   cocalc:info:hub starting webserver listening on 0.0.0.0:443 +1s
2022-04-20T00:03:10.620Z:   cocalc:info:init-http-redirect Creating redirect http://0.0.0.0 --> https://0.0.0.0 +0ms
2022-04-20T00:03:10.621Z:   cocalc:info:hub initializing primus websocket server +4ms
2022-04-20T00:03:10.693Z:   cocalc:info:primus listening on /hub +0ms
2022-04-20T00:03:12.914Z:   cocalc:info:hub Starting registering periodically with the database and updating a health check... +2s
2022-04-20T00:03:12.915Z:   cocalc:debug:hub hub_register.start... +2s
2022-04-20T00:03:12.915Z:   cocalc:debug:hub register_hub +0ms
2022-04-20T00:03:12.915Z:   cocalc:debug:hub register_hub -- doing db query +0ms
2022-04-20T00:03:12.919Z:   cocalc:debug:hub BLOCKED for 2213ms +4ms
2022-04-20T00:03:12.930Z:   cocalc:debug:hub register_hub -- success +11ms
2022-04-20T00:03:12.930Z:   cocalc:info:hub Started HUB!
  cocalc:info:hub *****
  cocalc:info:hub 
  cocalc:info:hub  https://0.0.0.0:443/
  cocalc:info:hub 
  cocalc:info:hub ***** +16ms
```

###

## Development

You can also change any code in `/cocalc/src/,` and generally do development, mostly as explained [here](https://github.com/sagemathinc/cocalc/blob/master/src/README.md), except you need to be root and change code in `/cocalc/src` instead of `~/cocalc/src.`   Also, be sure to do `umask 022.`  

## The PostgreSQL database

There is also a  PostgreSQL version 10 \(yes, that's old\) database running in cocalc\-docker.  It is setup using a standard system\-wide scripts, with configuration and log in the usual places. The database that the hub uses is determined by the env variables `PGHOST` and `PGUSER`.   In theory, you could set those \(in the Docker command line\) and use a completely different database. The defaults are setup in `/root/run.py`.

You can get a node.js command line with the same functionality as the core database code of CoCalc \(what's implemented in the package `@cocalc/database)` as follows: 

```sh
> sudo docker exec -it cocalc bash 
root@f9787faf32f4:/# cd /cocalc/src
root@f9787faf32f4:/cocalc/src# npm run c
...
Welcome to Node.js v14.19.1.
Type ".help" for more information.
> /cocalc/src
Logging debug info to the file "/tmp//log"
***

Logging to "/tmp/log" via the debug module
with  DEBUG='cocalc:*'.
Use   DEBUG_FILE='path' and DEBUG_CONSOLE=[yes|no] to override.
Using DEBUG='cocalc:*,-cocalc:silly:*' to control log levels.

***
db -- database
project('project_id') -- gives back object to control the porject
delete_account('email@foo.bar')  -- marks an account deleted
active_students() -- stats about student course projects during the last 30 days
stripe [account_id] -- update stripe info about user

(press return)
> 

# Then you can, e.g., update the database schema, which is something that should
# happen normally when you start up cocalc:

> db.update_schema({cb:console.log})
undefined
```

Look at /tmp/log to see any logging output.
