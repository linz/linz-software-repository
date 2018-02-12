# Debian packages builder

################################################################################
#
# Copyright 2013 Crown copyright (c)
# Land Information New Zealand and the New Zealand Government.
# All rights reserved
#
# This program is released under the terms of the new BSD license. See the
# LICENSE file for more information.
#
################################################################################

FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install -y \
    apt-transport-https \
    lsb-release

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" \
    > /etc/apt/sources.list.d/pgdg.list

RUN echo "deb https://packagecloud.io/linz/test/ubuntu/ $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/linz-prod.list

RUN echo "deb https://packagecloud.io/linz/prod/ubuntu/ $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/linz-prod.list

RUN apt-get update
RUN apt-get install -y \
    build-essential \
    curl \
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
