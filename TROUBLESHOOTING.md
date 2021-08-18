# Some troubleshooting steps that may be useful

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
root@367b9eb05898> pkill -f cocalc-hub-server
root@367b9eb05898> umask 022; cd /cocalc/src/smc-hub; npm run docker
...
```

You can also change any of code in ``/cocalc/src/smc-hub`, do `npm run build` there, then `npm run docker` to see the effect of your changes...

## The PostgreSQL database

There is also a  PostgreSQL database running in cocalc-docker.  It is setup using a standard system-wide scripts, with configuration and log in the usual places. The database that the hub uses is determined by the env variables `PGHOST` and `PGUSER` .   In theory, you could set those (when running Docker) and use a completely different database. The defaults are setup in `/root/run.py`.

