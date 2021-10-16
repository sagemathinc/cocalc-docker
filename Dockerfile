FROM ubuntu:20.04

MAINTAINER William Stein <wstein@sagemath.com>

USER root

# See https://github.com/sagemathinc/cocalc/issues/921
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV TERM screen


# So we can source (see http://goo.gl/oBPi5G)
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Ubuntu software that are used by CoCalc (latex, pandoc, sage)
RUN \
     apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
       software-properties-common \
       texlive-full \
       texlive-latex-extra \
       texlive-extra-utils \
       texlive-xetex \
       texlive-luatex \
       texlive-bibtex-extra \
       liblog-log4perl-perl

RUN \
    apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
       tmux \
       flex \
       bison \
       libreadline-dev \
       htop \
       screen \
       pandoc \
       aspell \
       poppler-utils \
       net-tools \
       wget \
       git \
       python3 \
       python \
       python3-pip \
       make \
       g++ \
       sudo \
       psmisc \
       rsync \
       tidy

 RUN \
     apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
       vim \
       inetutils-ping \
       lynx \
       telnet \
       git \
       emacs \
       subversion \
       ssh \
       m4 \
       latexmk \
       libpq5 \
       libpq-dev \
       build-essential \
       automake \
       jq

RUN \
   apt-get update \
&& DEBIAN_FRONTEND=noninteractive apt-get install -y \
       gfortran \
       dpkg-dev \
       libssl-dev \
       imagemagick \
       libcairo2-dev \
       libcurl4-openssl-dev \
       graphviz \
       smem \
       octave \
       locales \
       locales-all \
       postgresql \
       postgresql-contrib \
       clang-format \
       yapf3 \
       golang \
       r-cran-formatr \
       yasm

# Build and install Sage -- see https://github.com/sagemath/docker-images
COPY scripts/ /usr/sage-install-scripts/
RUN chmod -R a+rx /usr/sage-install-scripts/

RUN    adduser --quiet --shell /bin/bash --gecos "Sage user,101,," --disabled-password sage \
    && chown -R sage:sage /home/sage/

# make source checkout target, then run the install script
# see https://github.com/docker/docker/issues/9547 for the sync
# Sage can't be built as root, for reasons...
# Here -E inherits the environment from root, however it's important to
# include -H to set HOME=/home/sage, otherwise DOT_SAGE will not be set
# correctly and the build will fail!
RUN    mkdir -p /usr/local/sage \
    && chown -R sage:sage /usr/local/sage \
    && sudo -H -E -u sage /usr/sage-install-scripts/install_sage.sh /usr/local/ 9.2 \
    && sync

RUN /usr/sage-install-scripts/post_install_sage.sh /usr/local/ && rm -rf /tmp/* && sync

# Install SageTex
RUN \
     sudo -H -E -u sage sage -p sagetex \
  && cp -rv /usr/local/sage/local/share/texmf/tex/latex/sagetex/ /usr/share/texmf/tex/latex/ \
  && texhash

# Save nearly 5GB -- only do after installing all sage stuff!:
RUN rm -rf /usr/local/sage/build/pkgs/sagelib/src/build

RUN apt-get install -y python3-yaml   python3-matplotlib  python3-jupyter*  python3-ipywidgets jupyter

# install the Octave kernel.
# NOTE: we delete the spec file and use our own spec for the octave kernel, since the
# one that comes with Ubuntu 20.04 crashes (it uses python instead of python3).
RUN \
     pip3 install octave_kernel \
  && rm -rf /usr/local/share/jupyter/kernels/octave

# Pari/GP kernel support
RUN sage --pip install pari_jupyter

# Install LEAN proof assistant
RUN \
     export VERSION=3.4.1 \
  && mkdir -p /opt/lean \
  && cd /opt/lean \
  && wget https://github.com/leanprover/lean/releases/download/v$VERSION/lean-$VERSION-linux.tar.gz \
  && tar xf lean-$VERSION-linux.tar.gz \
  && rm lean-$VERSION-linux.tar.gz \
  && rm -f latest \
  && ln -s lean-$VERSION-linux latest \
  && ln -s /opt/lean/latest/bin/lean /usr/local/bin/lean

# Install all aspell dictionaries, so that spell check will work in all languages.  This is
# used by cocalc's spell checkers (for editors).  This takes about 80MB, which is well worth it.
RUN \
     apt-get update \
  && apt-get install -y aspell-*

RUN \
     wget -qO- https://deb.nodesource.com/setup_14.x | bash - \
  && apt-get install -y nodejs libxml2-dev libxslt-dev \
  && /usr/bin/npm install -g npm


# Kernel for javascript (the node.js Jupyter kernel)
RUN \
     npm install --unsafe-perm -g ijavascript \
  && ijsinstall --install=global

# Kernel for Typescript -- commented out since seems flakie and
# probably not generally interesting.
#RUN \
#     npm install --unsafe-perm -g itypescript \
#  && its --install=global

# Install Julia
ARG JULIA=1.6.1
RUN cd /tmp \
 && wget https://julialang-s3.julialang.org/bin/linux/x64/${JULIA%.*}/julia-${JULIA}-linux-x86_64.tar.gz \
 && tar xf julia-${JULIA}-linux-x86_64.tar.gz -C /opt \
 && rm  -f julia-${JULIA}-linux-x86_64.tar.gz \
 && mv /opt/julia-* /opt/julia \
 && ln -s /opt/julia/bin/julia /usr/local/bin

# Install R Jupyter Kernel package into R itself (so R kernel works), and some other packages e.g., rmarkdown which requires reticulate to use Python.
RUN echo "install.packages(c('repr', 'IRdisplay', 'evaluate', 'crayon', 'pbdZMQ', 'httr', 'devtools', 'uuid', 'digest', 'IRkernel', 'formatR'), repos='https://cloud.r-project.org')" | sage -R --no-save
RUN echo "install.packages(c('repr', 'IRdisplay', 'evaluate', 'crayon', 'pbdZMQ', 'httr', 'devtools', 'uuid', 'digest', 'IRkernel', 'rmarkdown', 'reticulate', 'formatR'), repos='https://cloud.r-project.org')" | R --no-save

# Xpra backend support -- we have to use the debs from xpra.org,
RUN \
     apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y xvfb xsel websockify curl xpra

# X11 apps to make x11 support useful.
RUN \
     apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y x11-apps dbus-x11 gnome-terminal \
     vim-gtk lyx libreoffice inkscape gimp firefox texstudio evince mesa-utils \
     xdotool xclip x11-xkb-utils

# VSCode code-server web application
# See https://github.com/cdr/code-server/releases for VERSION.
RUN \
     export VERSION=3.11.0 \
  && curl -fOL https://github.com/cdr/code-server/releases/download/v$VERSION/code-server_"$VERSION"_amd64.deb \
  && dpkg -i code-server_"$VERSION"_amd64.deb \
  && rm code-server_"$VERSION"_amd64.deb


# Commit to checkout and build.
ARG BRANCH=master
ARG commit=HEAD

# Pull latest source code for CoCalc and checkout requested commit (or HEAD),
# install our Python libraries globally, then remove cocalc.  We only need it
# for installing these Python libraries (TODO: move to pypi?).
RUN \
     umask 022 && git clone --depth=1 https://github.com/sagemathinc/cocalc.git \
  && cd /cocalc && git pull && git fetch -u origin $BRANCH:$BRANCH && git checkout ${commit:-HEAD}

RUN umask 022 && pip3 install --upgrade /cocalc/src/smc_pyutil/

# Install code into Sage
RUN umask 022 && sage -pip install --upgrade /cocalc/src/smc_sagews/

# Build cocalc itself
RUN umask 022 && cd /cocalc/src && npm run make

# And cleanup npm cache, which is several hundred megabytes after building cocalc above.
RUN rm -rf /root/.npm

RUN echo "umask 077" >> /etc/bash.bashrc

# Install some Jupyter kernel definitions
COPY kernels /usr/local/share/jupyter/kernels

# Configure so that R kernel actually works -- see https://github.com/IRkernel/IRkernel/issues/388
COPY kernels/ir/Rprofile.site /usr/local/sage/local/lib/R/etc/Rprofile.site

# Build a UTF-8 locale, so that tmux works -- see https://unix.stackexchange.com/questions/277909/updated-my-arch-linux-server-and-now-i-get-tmux-need-utf-8-locale-lc-ctype-bu
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

# Install IJulia kernel
# I figured out the dierectory /opt/julia/local/share/julia by inspecting the global varaible
# DEPOT_PATH from within a running Julia session as a normal user, and also reading julia docs:
#    https://pkgdocs.julialang.org/v1/glossary/
# It was *incredibly* confusing, and the dozens of discussions of this problem that one finds
# via Google are all very wrong, incomplete, misleading, etc.  It's truly amazing how 
# disorganized-wrt-Google information about Julia is, as compared to Node.js and Python. 
RUN echo 'using Pkg; Pkg.add("IJulia");' | JUPYTER=/usr/local/bin/jupyter JULIA_DEPOT_PATH=/opt/julia/local/share/julia JULIA_PKG=/opt/julia/local/share/julia julia
RUN mv "$HOME/.local/share/jupyter/kernels/julia"* "/usr/local/share/jupyter/kernels/"

# Also add Pluto system-wide, since we'll likely support it soon in cocalc, and also
# Nemo and Hecke (some math software).
RUN echo 'using Pkg; Pkg.add("Pluto"); Pkg.add("Nemo"); Pkg.add("Hecke")' | JULIA_DEPOT_PATH=/opt/julia/local/share/julia JULIA_PKG=/opt/julia/local/share/julia julia


# Configuration

COPY login.defs /etc/login.defs
COPY login /etc/defaults/login
COPY run.py /root/run.py
COPY bashrc /root/.bashrc


# CoCalc Jupyter widgets
RUN \
  pip3 install --no-cache-dir ipyleaflet

# The Jupyter kernel that gets auto-installed with some other jupyter Ubuntu packages
# doesn't have some nice options regarding inline matplotlib (and possibly others), so
# we delete it.
RUN rm -rf /usr/share/jupyter/kernels/python3

# Fix pythontex for our use
RUN ln -sf /usr/bin/pythontex /usr/bin/pythontex3

# Fix yapf for our use
RUN ln -sf /usr/bin/yapf3 /usr/bin/yapf

# Other pip3 packages
# NOTE: Upgrading zmq is very important, or the Ubuntu version breaks everything..
RUN \
  pip3 install --upgrade --no-cache-dir  pandas plotly scipy  scikit-learn seaborn bokeh zmq

# We stick with PostgreSQL 10 for now, to avoid any issues with users having to
# update to an incompatible version 12.  We don't use postgresql-12 features *yet*,
# and won't upgrade until we need to or it becomes a security liability.  Note that
# PostgreSQL 10 is officially supported until November 10, 2022 according to
# https://www.postgresql.org/support/versioning/
RUN \
     sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
  && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
  && apt-get update \
  && apt-get install -y  postgresql-10

CMD /root/run.py

ARG BUILD_DATE
LABEL org.label-schema.build-date=$BUILD_DATE

EXPOSE 22 80 443
