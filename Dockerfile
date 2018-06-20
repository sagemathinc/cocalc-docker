FROM ubuntu:18.04

MAINTAINER William Stein <wstein@sagemath.com>

USER root

# See https://github.com/sagemathinc/cocalc/issues/921
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV TERM screen


# So we can source (see http://goo.gl/oBPi5G)
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Ubuntu software that are used by CoCalc (latex, pandoc, sage, jupyter)
RUN \
     apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
       software-properties-common \
       texlive \
       texlive-latex-extra \
       texlive-extra-utils \
       texlive-xetex \
       texlive-luatex

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
       python \
       python-pip \
       make \
       g++ \
       sudo \
       psmisc \
       haproxy \
       nginx

 RUN \
     apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y \
       vim \
       bup \
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
       automake

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
       python3-yaml \
       locales \
       locales-all \
       postgresql \
       postgresql-contrib

# Jupyter from pip (since apt-get jupyter is ancient)
RUN \
  pip install "ipython<6" jupyter

# Build and install Sage -- see https://github.com/sagemath/docker-images
COPY scripts/ /tmp/scripts
RUN chmod -R +x /tmp/scripts

RUN    adduser --quiet --shell /bin/bash --gecos "Sage user,101,," --disabled-password sage \
    && chown -R sage:sage /home/sage/

# make source checkout target, then run the install script
# see https://github.com/docker/docker/issues/9547 for the sync
RUN    mkdir -p /usr/local/ \
    && /tmp/scripts/install_sage.sh /usr/local/ master \
    && sync

RUN /tmp/scripts/post_install_sage.sh && rm -rf /tmp/* && sync

# Install sage scripts system-wide
RUN echo "install_scripts('/usr/local/bin/')" | sage

# Install SageTex
RUN \
     sudo -H -E -u sage sage -p sagetex \
  && cp -rv /usr/local/sage/local/share/texmf/tex/latex/sagetex/ /usr/share/texmf/tex/latex/ \
  && texhash

# Install Node.js and LATEST version of npm
RUN \
  wget -qO- https://deb.nodesource.com/setup_8.x | bash - && \
  apt-get install -y nodejs && \
  /usr/bin/npm install -g npm

# Commit to checkout and build.
ARG commit=HEAD

# Pull latest source code for CoCalc and checkout requested commit (or HEAD)
RUN \
  git clone https://github.com/sagemathinc/cocalc.git && \
  cd /cocalc && git pull && git fetch origin && git checkout ${commit:-HEAD}

# Build and install all deps
# CRITICAL to install first web, then compute, since compute precompiles all the .js
# for fast startup, but unfortunately doing so breaks ./install.py all --web, since
# the .js files laying around somehow mess up cjsx loading. 
RUN \
     cd /cocalc/src \
  && . ./smc-env \
  && ./install.py all --web \
  && ./install.py all --compute \
  && rm -rf /root/.npm /root/.node-gyp/

# Install code into Sage
RUN cd /cocalc/src && sage -pip install --upgrade smc_sagews/

RUN echo "umask 077" >> /etc/bash.bashrc

# Install R Jupyter Kernel package into R itself (so R kernel works)
RUN echo "install.packages(c('repr', 'IRdisplay', 'evaluate', 'crayon', 'pbdZMQ', 'httr', 'devtools', 'uuid', 'digest'), repos='http://cran.us.r-project.org'); devtools::install_github('IRkernel/IRkernel')" | sage -R --no-save

# Install some Jupyter kernel definitions
COPY kernels /usr/local/share/jupyter/kernels

# Configure so that R kernel actually works -- see https://github.com/IRkernel/IRkernel/issues/388
COPY kernels/ir/Rprofile.site /usr/local/sage/local/lib/R/etc/Rprofile.site

# Build a UTF-8 locale, so that tmux works -- see https://unix.stackexchange.com/questions/277909/updated-my-arch-linux-server-and-now-i-get-tmux-need-utf-8-locale-lc-ctype-bu
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

# Install Julia
ARG JULIA=0.6.3
RUN cd /tmp \
 && wget https://julialang-s3.julialang.org/bin/linux/x64/0.6/julia-${JULIA}-linux-x86_64.tar.gz \
 && tar xf julia-${JULIA}-linux-x86_64.tar.gz -C /opt \
 && rm  -f julia-${JULIA}-linux-x86_64.tar.gz \
 && mv /opt/julia-* /opt/julia \
 && ln -s /opt/julia/bin/julia /usr/local/bin

# Install IJulia kernel
RUN echo '\
ENV["JUPYTER"] = "/usr/local/bin/jupyter"; \
ENV["JULIA_PKGDIR"] = "/opt/julia/share/julia/site"; \
Pkg.init(); \
Pkg.add("IJulia");' | julia \
 && mv -i "$HOME/.local/share/jupyter/kernels/julia-0.6" "/usr/local/share/jupyter/kernels/"

###

# Install a script to obtain a ssl certificate from letsencrypt

RUN apt-get update && apt-get install -y curl

COPY letsencrypt-cert.sh /usr/local/sbin/letsencrypt-cert

RUN cd "/usr/local/sbin" \
 && wget "https://github.com/lukas2511/dehydrated/raw/0be0ab083f290afbc757b8388a80df458ddfd33c/dehydrated" \
 && echo f1d5ad195669afd315b68af5d6099bdf36a8532bdc0b4a997b1e7139424d7a56 dehydrated | sha256sum -c \
 && chmod +x "/usr/local/sbin/dehydrated" \
 && chmod +x "/usr/local/sbin/letsencrypt-cert"

### Configuration

COPY login.defs /etc/login.defs
COPY login /etc/defaults/login
COPY nginx.conf /etc/nginx/sites-available/default
COPY haproxy.conf /etc/haproxy/haproxy.cfg
COPY run.py /root/run.py
COPY bashrc /root/.bashrc

CMD /root/run.py

EXPOSE 80 443
