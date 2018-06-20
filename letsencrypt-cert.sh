#! /bin/bash

progname=$(basename $0)

usage ()
{
  echo "$progname setup [--test] <DOMAIN> <EMAIL>"
  echo "$progname renew"
  exit 1
}

CA_PRODUCTION="https://acme-v01.api.letsencrypt.org/directory"
CA_STAGING="https://acme-staging.api.letsencrypt.org/directory"

BASEDIR="/projects/conf/dehydrated"
WELLKNOWN="/run/acme-challenge"
HAPROXY_CRT="/run/haproxy.pem"

case "$1" in
    renew)
        if [ ! -f "$BASEDIR/conf" ]
        then
            echo "To setup please run"
            echo
            echo "    $progname setup [--test] <DOMAIN> <EMAIL>"
            echo
            exit 1
        fi
        mkdir -p "$WELLKNOWN"
        chown www-data: "$WELLKNOWN"
        dehydrated -f "$BASEDIR/conf" -c
        exit $?
        ;;
    setup)
        shift
        if [[ "$1" = "--test" ]]
        then
            shift
            CA="\$CA_STAGING"
        else
            CA="\$CA_PRODUCTION"
        fi
        [[ $# = 2 ]] || usage
        ;;
    *)
        usage
        ;;
esac

DOMAIN="$1"
EMAIL="$2"

mkdir -p "$BASEDIR"

[ -f "$BASEDIR/conf" ] ||
    cat << EOF > "$BASEDIR/conf"
CA_PRODUCTION="$CA_PRODUCTION"
CA_STAGING="$CA_STAGING"
CA="$CA"

CONTACT_EMAIL="$EMAIL"

BASEDIR="$BASEDIR"
WELLKNOWN="$WELLKNOWN"

deploy_cert () {
    if [[ "\$1" = "deploy_cert" ]]
    then
        # FULLCHAINFILE + KEYFILE
        cat "\$5" "\$3" > "$HAPROXY_CRT"
        cp "$HAPROXY_CRT" "/projects/conf/nopassphrase.pem"
        service haproxy reload
    fi
}
HOOK=deploy_cert
EOF

[ -f "$BASEDIR/domains.txt" ] ||
    echo "$DOMAIN" > "$BASEDIR/domains.txt"

dehydrated -f "$BASEDIR/conf" --register --accept-terms


echo To install the certificates you must run
echo
echo "    $progname renew"
echo
echo and repeat periodically to renew.
echo
echo Configuration is in "$BASEDIR/conf" and "$BASEDIR/domains.txt".
echo For documentation see https://github.com/lukas2511/dehydrated
