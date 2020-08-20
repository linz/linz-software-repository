# Debian packages builder

################################################################################
#
# Copyright 2013-2020 Crown copyright (c)
# Land Information New Zealand and the New Zealand Government.
# All rights reserved
#
# This program is released under the terms of the new BSD license. See the
# LICENSE file for more information.
#
################################################################################

# Pass via env, like: docker build --build-arg DISTRIBUTION=18.04 ...
ARG  DISTRIBUTION=bionic
FROM ubuntu:${DISTRIBUTION}

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install -y \
    apt-transport-https \
    build-essential \
    ca-certificates \
    curl \
    devscripts \
    equivs \
    git \
    git-buildpackage \
    gnupg \
    lsb-release \
    make \
    software-properties-common \
    wget

ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn
RUN curl -s https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" \
    > /etc/apt/sources.list.d/pgdg.list

RUN curl -s https://packagecloud.io/install/repositories/linz/test/script.deb.sh | bash
RUN curl -s https://packagecloud.io/install/repositories/linz/prod/script.deb.sh | bash


# Install ruby2.3, for packagecloud
RUN add-apt-repository -y ppa:brightbox/ruby-ng
RUN apt-get update && apt-get -y install ruby2.3 ruby2.3-dev

## Workaround for packagecloud tool bug,
## see https://github.com/rubygems/rubygems/issues/3068#issuecomment-574775885
ENV REALLY_GEM_UPDATE_SYSTEM=1
## 3.0.6
RUN gem update --system 3.0.6
RUN gem install rake
RUN gem install package_cloud


RUN echo "DEBIAN_FRONTEND=noninteractive" >> /etc/environment

ADD bin/* /usr/local/bin/
RUN chmod 755 /usr/local/bin/*

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
