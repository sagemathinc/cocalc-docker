#!/usr/bin/env bash

set -ev

export DEBIAN_FRONTEND=noninteractive

apt-get update

apt-get install -y \
       software-properties-common \
       tmux \
       flex \
       bison \
       libreadline-dev \
       poppler-utils \
       net-tools \
       wget \
       curl \
       git \
       python3 \
       python-is-python3 \
       python3-pip \
       make \
       g++ \
       sudo \
       psmisc \
       rsync \
       tidy \
       vim \
       inetutils-ping \
       lynx \
       telnet \
       git \
       ssh \
       m4 \
       latexmk \
       libpq5 \
       libpq-dev \
       build-essential \
       automake \
       jq \
       bsdmainutils \
       postgresql \
       libfuse-dev \
       pkg-config \
       lz4