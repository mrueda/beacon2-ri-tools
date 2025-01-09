# Use Ubuntu 20.04 as the base image
FROM ubuntu:20.04

# Maintainer Information
LABEL maintainer="Manuel Rueda <manuel.rueda@cnag.eu>"

# Set non-interactive environment for apt operations
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages and Python modules
RUN apt-get update && apt-get install -y \
    apt-utils wget bzip2 git cpanminus perl-doc gcc make \
    libbz2-dev zlib1g-dev libncurses5-dev libncursesw5-dev \
    liblzma-dev libcurl4-openssl-dev pkg-config libssl-dev \
    aria2 unzip jq vim sudo default-jre python3-pip && \
    pip install xlsx2csv flask pandas && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create application directory and clone the repository
RUN mkdir -p /usr/share/beacon-ri
WORKDIR /usr/share/beacon-ri/
RUN git clone https://github.com/mrueda/beacon2-ri-tools.git

# Install Perl dependencies
WORKDIR /usr/share/beacon-ri/beacon2-ri-tools
RUN cpanm --notest --installdeps .

# Add a non-root user
ARG UID=1000
ARG GID=1000
RUN groupadd -g "${GID}" dockeruser && \
    useradd --create-home --no-log-init -u "${UID}" -g "${GID}" dockeruser

# Uncomment the following line to run the container as dockeruser
# USER dockeruser

# Set the working directory back to the application directory
WORKDIR /usr/share/beacon-ri/
