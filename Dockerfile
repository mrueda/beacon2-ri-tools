FROM ubuntu:20.04

# File Maintainer
LABEL maintainer="Manuel Rueda <manuel.rueda@cnag.eu>"

# Build env 
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get -y install apt-utils wget bzip2 git cpanminus perl-doc gcc make libbz2-dev zlib1g-dev libncurses5-dev libncursesw5-dev liblzma-dev libcurl4-openssl-dev pkg-config libssl-dev aria2 unzip jq vim sudo default-jre python3-pip && \
    pip install xlsx2csv

# Download app
RUN mkdir /usr/share/beacon-ri
WORKDIR /usr/share/beacon-ri/
RUN git clone https://github.com/mrueda/beacon2-ri-tools.git

# Install Perl modules
WORKDIR /usr/share/beacon-ri/beacon2-ri-tools
RUN cpanm --notest --installdeps .

# Add user "dockeruser"
ARG UID=1000
ARG GID=1000

RUN groupadd -g "${GID}" dockeruser \
  && useradd --create-home --no-log-init -u "${UID}" -g "${GID}" dockeruser

# To change default user from root -> dockeruser
#USER dockeruser

# Get back to entry dir
WORKDIR /usr/share/beacon-ri/
