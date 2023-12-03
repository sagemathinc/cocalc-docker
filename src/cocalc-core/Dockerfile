ARG MYAPP_IMAGE=ubuntu:22.04
FROM $MYAPP_IMAGE AS build_image

MAINTAINER William Stein <wstein@sagemath.com>

USER root

# Ensure umask is 022 everywhere
RUN echo "umask 022" >> /etc/bash.bashrc

# See https://github.com/sagemathinc/cocalc/issues/921
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en

# Ubuntu software needed to build cocalc
RUN \
     apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
       git \
       curl \
       make \
       g++ \
       fuse \
       libfuse-dev \
       pkg-config \
       python3 \
       python3-pip

# This is needed in the cocalc build
RUN pip3 install pyyaml

COPY scripts/install-nodejs.sh /tmp/install-nodejs.sh
RUN /tmp/install-nodejs.sh

# Get the commit to checkout and build:
ARG BRANCH=master
ARG COMMIT=HEAD

# Pull latest source code for CoCalc and checkout requested commit
RUN git clone --depth=1 https://github.com/sagemathinc/cocalc.git \
  && cd /cocalc && git pull && git fetch -u origin $BRANCH:$BRANCH && git checkout ${COMMIT:-HEAD}

RUN cd /cocalc/src && pnpm build

# Delete packages that were only needed for the build.
# Deleting node_modules and installing is the recommended approach by pnpm.
RUN cd /cocalc/src/packages && rm -rf node_modules && pnpm install --prod

RUN rm -rf /cocalc/.git

# remove the 9MB sqlite source code, which we don't need
RUN rm -f /cocalc/src/packages/node_modules/.pnpm/better-sqlite3*/node_modules/better-sqlite3/deps/sqlite3/sqlite3.c

# 2-stage build to minimize wasted space
FROM $MYAPP_IMAGE

# Copy the cocalc directory from the build image.
COPY --from=build_image /cocalc /cocalc

