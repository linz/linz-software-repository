# Debian packages builder

################################################################################
#
# Copyright 2013-2019 Crown copyright (c)
# Land Information New Zealand and the New Zealand Government.
# All rights reserved
#
# This program is released under the terms of the new BSD license. See the
# LICENSE file for more information.
#
################################################################################

# Replace DISTRIBUTION with required Ubuntu
# distribution number (14.04, 16.04, ...)
FROM ubuntu:DISTRIBUTION

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn
RUN curl -s https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" \
    > /etc/apt/sources.list.d/pgdg.list

RUN curl -s https://packagecloud.io/install/repositories/linz/test/script.deb.sh | bash
RUN curl -s https://packagecloud.io/install/repositories/linz/prod/script.deb.sh | bash


RUN apt-get update
RUN apt-get install -y \
    build-essential \
    devscripts \
    equivs \
    git \
    git-buildpackage \
    make \
    wget

RUN echo "DEBIAN_FRONTEND=noninteractive" >> /etc/environment

ADD bin/* /usr/local/bin/
RUN chmod 755 /usr/local/bin/*

ENTRYPOINT /bin/bash
