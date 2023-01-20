#!/usr/bin/env python3

# NOTE: There is a simpler different variant of this script in the personal/ subdirectory.

import os, tempfile, time, shutil, subprocess, sys


# Only actually set the vars in case they aren't already set.
# This makes it possible for users to use a custom remote PostgreSQL
# server if they want.
if 'PGHOST' not in os.environ:
    local_database = True
    # Where the PostgreSQL data is stored
    PGDATA = '/projects/postgres/data'
    PGHOST = os.path.join(PGDATA, 'socket')
    os.environ['PGHOST'] = PGHOST
else:
    local_database = False

if 'PGUSER' not in os.environ:
    os.environ['PGUSER'] = 'smc'

if 'PGDATABASE' not in os.environ:
    os.environ['PGDATABASE'] = 'smc'

# ensure that everything we spawn has this umask, which is more secure.
os.umask(0o077)

join = os.path.join


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


def self_signed_cert():
    log("self_signed_cert")
    target = '/projects/conf/cert'
    if not os.path.exists(target):
        os.makedirs(target)
    key = os.path.join(target, 'key.pem')
    cert = os.path.join(target, 'cert.pem')
    if os.path.exists(key) and os.path.exists(cert):
        log("ssl key and cert exist, so doing nothing further")
        return
    log(f"create self_signed key={key} and cert={cert}")
    run([
        'openssl', 'req', '-new', '-x509', '-nodes', '-out', cert, '-keyout',
        key, '-subj', '/C=US/ST=WA/L=WA/O=Network/OU=IT Department/CN=cocalc'
    ],
        path=target)
    run("chmod og-rwx /projects/conf")


def init_projects_path():
    log("init_projects_path: initialize /projects path")
    if not os.path.exists('/projects'):
        log("WARNING: container data will be EPHEMERAL -- in /projects")
        os.makedirs('/projects')
    # Ensure that users can see their own home directories:
    os.system("chmod a+rx /projects")
    for path in ['conf']:
        full_path = join('/projects', path)
        if not os.path.exists(full_path):
            log("creating ", full_path)
            os.makedirs(full_path)
            run("chmod og-rwx '%s'" % full_path)


def start_ssh():
    log("start_ssh")
    log("starting ssh")
    run('service ssh start')


def root_ssh_keys():
    log("root_ssh_keys: creating them")
    run("rm -rf /root/.ssh/")
    run("ssh-keygen -t ecdsa -N '' -f /root/.ssh/id_ecdsa")
    run("cp -v /root/.ssh/id_ecdsa.pub /root/.ssh/authorized_keys")


def start_hub():
    log("start_hub")
    kill("cocalc-hub-server")
    # NOTE: there's automatic logging to files that rotate as they get bigger...
    run("mkdir -p /var/log/hub && cd /cocalc/src/packages/hub && pnpm run hub-docker-prod > /var/log/hub/out 2>/var/log/hub/err &")

def postgres_perms():
    log("postgres_perms: ensuring postgres directory perms are sufficiently restrictive"
        )
    run("mkdir -p /projects/postgres && chown -R sage. /projects/postgres && chmod og-rwx -R /projects/postgres"
        )


def start_postgres():
    log("start_postgres")
    for var in ['PGHOST', 'PGUSER', 'PGDATABASE']:
        log("start_postgres: %s=%s"%(var, os.environ[var]))
    if not local_database:
        log("start_postgres -- using external database so nothing to do")
        return
    log("start_postgres -- using local database")
    postgres_perms()
    if not os.path.exists(
            PGDATA):  # see comments in smc/src/dev/project/start_postgres.py
        log("start_postgres:", "create data directory ", PGDATA)
        run("sudo -u sage /usr/lib/postgresql/10/bin/pg_ctl init -D '%s'" %
            PGDATA)
        open(os.path.join(PGDATA, 'pg_hba.conf'),
             'w').write("local all all trust")
        conf = os.path.join(PGDATA, 'postgresql.conf')
        s = open(conf).read(
        ) + "\nunix_socket_directories = '%s'\nlisten_addresses=''\n" % PGHOST
        open(conf, 'w').write(s)
        os.makedirs(PGHOST)
        postgres_perms()
        run("sudo -u sage /usr/lib/postgresql/10/bin/postgres -D '%s' >%s/postgres.log 2>&1 &"
            % (PGDATA, PGDATA))
        time.sleep(5)
        run("sudo -u sage /usr/lib/postgresql/10/bin/createuser -h '%s' -sE smc"
            % PGHOST)
        run("sudo -u sage kill %s" %
            (open(os.path.join(PGDATA, 'postmaster.pid')).read().split()[0]))
        time.sleep(3)
    log("start_postgres:", "starting the server")
    os.system(
        "sudo -u sage /usr/lib/postgresql/10/bin/postgres -D '%s' > /var/log/postgres.log 2>&1 &"
        % PGDATA)




def main():
    init_projects_path()
    self_signed_cert()
    root_ssh_keys()
    start_ssh()
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
