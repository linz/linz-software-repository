# Debian packages builder

FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get install -y lsb-release

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" \
    > /etc/apt/sources.list.d/pgdg.list

RUN apt-get update
RUN apt-get install -y \
    build-essential \
    curl \
    devscripts \
    equivs \
    git-buildpackage \
    git \
    make \
    wget

RUN echo "DEBIAN_FRONTEND=noninteractive" >> /etc/environment

ADD bin/* /usr/local/bin/
RUN chmod 755 /usr/local/bin/*

ENTRYPOINT /bin/bash
