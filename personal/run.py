#!/usr/bin/env python3

import os, tempfile, time, shutil, subprocess, sys

join = os.path.join

os.chdir("/home/user/cocalc/src")

os.environ['PATH'] = "/usr/lib/postgresql/14/bin/:" + os.environ['PATH']

# We only set these environment variables if they are not already set.
if 'PGHOST' not in os.environ:
    local_database = True
    os.environ['PGHOST'] = "/home/user/socket"
    if not os.path.exists(os.environ['PGHOST']):
        os.makedirs(os.environ['PGHOST'])
else:
    local_database = False

if 'PGUSER' not in os.environ:
    os.environ['PGUSER'] = 'smc'
if 'PGDATABASE' not in os.environ:
    os.environ['PGDATABASE'] = 'smc'

def log(*args):
    print("LOG:", *args)
    sys.stdout.flush()


def run(v, shell=False, path='.', get_output=False, env=None, verbose=1):
    log("run %s" % v)
    t = time.time()
    if isinstance(v, str):
        cmd = v
        shell = True
    else:
        cmd = ' '.join([(x if len(x.split()) <= 1 else '"%s"' % x) for x in v])
    if path != '.':
        cur = os.path.abspath(os.curdir)
        if verbose:
            print('chdir %s' % path)
        os.chdir(path)
    try:
        if verbose:
            print(cmd)
        if shell:
            kwds = {'shell': True, 'executable': '/bin/bash', 'env': env}
        else:
            kwds = {'env': env}
        if get_output:
            output = subprocess.Popen(v, stdout=subprocess.PIPE,
                                      **kwds).stdout.read().decode()
        else:
            if subprocess.call(v, **kwds):
                raise RuntimeError("error running '{cmd}'".format(cmd=cmd))
            output = None
        seconds = time.time() - t
        if verbose > 1:
            print("TOTAL TIME: {seconds} seconds -- to run '{cmd}'".format(
                seconds=seconds, cmd=cmd))
        return output
    finally:
        if path != '.':
            os.chdir(cur)


def kill(c):
    try:
        run("pkill -f %s" % c)
    except:
        pass


def init_projects_path():
    log("init_projects_path: initialize /projects path")
    if not os.path.exists('/home/user/cocalc/src/data/projects'):
        os.makedirs('/home/user/cocalc/src/data/projects')
    for path in ['conf']:
        full_path = join('/home/user/cocalc/src/data/projects', path)
        if not os.path.exists(full_path):
            log("creating ", full_path)
            os.makedirs(full_path)


def start_hub():
    log("start_hub")
    kill("cocalc-hub-server")
    # PORT here must match what is exposed in the Dockerfile-personal
    log("Hub logs are in /home/user/logs/")
    run("mkdir -p /home/user/logs/ && cd packages/hub/ && unset DATA COCALC_ROOT BASE_PATH && PORT=5000 DEBUG='cocalc:*,-cocalc:silly:*',$DEBUG NODE_ENV=production NODE_OPTIONS='--max_old_space_size=16000' pnpm exec cocalc-hub-server --mode=single-user --all --hostname=0.0.0.0 --personal > /home/user/logs/cocalc.out 2>/home/user/logs/cocalc.err &"
        )


def start_postgres():
    log("start_postgres")
    log("start_postgres")
    for var in ['PGHOST', 'PGUSER', 'PGDATABASE']:
        log("start_postgres: %s=%s"%(var, os.environ[var]))
    if not local_database:
        log("start_postgres -- using external database so nothing to do")
        return
    log("Hub logs are in /home/user/logs/")
    run("mkdir -p /home/user/logs/ && cd /home/user/cocalc/src && npm run database > /home/user/logs/postgres.out 2>/home/user/logs/postgres.err & "
        )


def main():
    init_projects_path()
    start_postgres()
    start_hub()
    while True:
        log("Started services.")
        os.wait()


if __name__ == "__main__":
    try:
        main()
    except Exception as err:
        log("Failed to start -", err)
        log("Pausing indefinitely so you can try to debug this...")
        while True:
            time.sleep(60)
