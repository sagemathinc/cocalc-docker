#!/usr/bin/env bash

set -ev

export BRANCH=${BRANCH:-master}
export COMMIT=${COMMIT:-HEAD}

# Pull latest source code for CoCalc and checkout requested commit (or HEAD),
# install our Python libraries globally, then remove cocalc.  We only need it
# for installing these Python libraries (TODO: move to pypi?).

# This script assume npm, pnpm and python are installed already.  It also installs
# some scripts into sage, if sage is installed.

umask 022
cd /
git clone --depth=1 https://github.com/sagemathinc/cocalc.git
cd /cocalc/src
git pull
git fetch -u origin $BRANCH:$BRANCH
git checkout $COMMIT

pip3 install --upgrade ./smc_pyutil/

# Install code into Sage if there is a "sage" command in the path:
# Install code into Sage if there is a "sage" command in the path:
if command -v sage >/dev/null 2>&1; then
   sage -pip install --upgrade ./smc_sagews/
fi;

# Build cocalc itself.
npm run build

# Cleanup pnpm cache
pnpm store prune