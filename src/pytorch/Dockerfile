# This builds a Docker image for CoCalc, which is an online platform for
# collaborative mathematical computation. It installs software for CoCalc
# including latex, pandoc, tmux, flex, bison, and various other packages. It also
# the R statistical software, SageMath (copying from another Docker build), and
# the Julia programming language. Finally, it installs
# various Jupyter kernels, including ones for Python, Octave, and JavaScript. The
# image is built on top of the Ubuntu 22.04 operating system.


ARG MYAPP_IMAGE=nvcr.io/nvidia/pytorch:23.10-py3
FROM $MYAPP_IMAGE

MAINTAINER William Stein <wstein@sagemath.com>

USER root

# See https://github.com/sagemathinc/cocalc/issues/921
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV TERM screen

# Basic software
COPY scripts/install-core-ubuntu-packages.sh /tmp/install-core-ubuntu-packages.sh
RUN /tmp/install-core-ubuntu-packages.sh

# Nodejs
COPY scripts/install-nodejs.sh /tmp/install-nodejs.sh
RUN /tmp/install-nodejs.sh

# CoCalc
COPY scripts/install-cocalc.sh /tmp/install-cocalc.sh
RUN /tmp/install-cocalc.sh



