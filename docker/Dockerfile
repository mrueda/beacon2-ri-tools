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
    unzip jq vim sudo default-jre python3-pip && \
    pip install xlsx2csv flask pandas && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install mongosh (MongoDB Shell)
RUN apt-get update && apt-get install -y gnupg && \
    wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add - && \
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" \
        | tee /etc/apt/sources.list.d/mongodb-org-6.0.list && \
    apt-get update && apt-get install -y mongodb-mongosh && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /usr/share/

# Clone the repository
RUN git clone https://github.com/CNAG-Biomedical-Informatics/beacon2-cbi-tools.git

# Remove the .git folder to save space and avoid shipping VCS data
RUN rm -rf beacon2-cbi-tools/.git

# Install Perl dependencies
WORKDIR /usr/share/beacon2-cbi-tools
RUN cpanm --notest --installdeps . && rm -rf /root/.cpanm/work/*

# Add a non-root user
ARG UID=1000
ARG GID=1000
RUN groupadd -g "${GID}" dockeruser && \
    useradd --create-home --no-log-init -u "${UID}" -g "${GID}" dockeruser

# Uncomment the following line to run the container as dockeruser
# USER dockeruser
