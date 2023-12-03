#!/usr/bin/env bash
# Install nodejs v18.17.1 using nvm

set -ev


# CRITICAL:  Do *NOT* upgrade nodejs to a newer version until the following is fixed !!!!!!
#    https://github.com/sagemathinc/cocalc/issues/6963
#
export NODE_VERSION=18.17.1

# See https://github.com/nvm-sh/nvm#install--update-script for nvm versions
export NVM_VERSION=0.39.5

mkdir -p /usr/local/nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v$NVM_VERSION/install.sh | NVM_DIR=/usr/local/nvm bash
source /usr/local/nvm/nvm.sh

nvm install --no-progress $NODE_VERSION

# make the version we just installed the default
# no matter what else might be around (e.g., nvidia images
# also have node 16...)
nvm alias default $NODE_VERSION

# save space
rm -rf /usr/local/nvm/.git/

nvm use $NODE_VERSION
npm install -g npm pnpm

# We copy the install over to /usr/local, so it's available globally
# without users having to do anything special.  If they setup nvm
# though, at least our version is the default also, since we set it
# above as the default.
n=$(which node);n=${n%/bin/node}; chmod -R 755 $n/bin/*; cp -r $n/{bin,lib,share} /usr/local
