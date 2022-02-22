# Debian packages builder

################################################################################
#
# Copyright 2013-2022 Crown copyright (c)
# Land Information New Zealand and the New Zealand Government.
# All rights reserved
#
# This program is released under the terms of the new BSD license. See the
# LICENSE file for more information.
#
################################################################################

# Pass via env, like: docker build --build-arg DISTRIBUTION=18.04 ...
ARG DISTRIBUTION
FROM ubuntu:${DISTRIBUTION}

SHELL ["/bin/bash", "-o", "errexit", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND noninteractive

# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get --assume-yes install --no-install-recommends \
        apt-transport-https \
        build-essential \
        ca-certificates \
        curl \
        devscripts \
        equivs \
        git \
        git-buildpackage \
        gnupg \
        jq \
        lsb-release \
        make \
        ruby \
        ruby-dev \
        software-properties-common \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=DontWarn
RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" \
    > /etc/apt/sources.list.d/pgdg.list

RUN curl https://packagecloud.io/install/repositories/linz/test/script.deb.sh | \
    os=ubuntu dist=focal bash
RUN curl https://packagecloud.io/install/repositories/linz/prod/script.deb.sh | \
    os=ubuntu dist=focal bash

COPY Gemfile Gemfile.lock /tmp/
RUN gem install bundler:2.3.6 \
    && bundle install --gemfile=/tmp/Gemfile

# Avoid interactive prompts when running APT commands
ENV DEBIAN_FRONTEND=noninteractive

COPY bin/* /usr/local/bin/
RUN chmod 755 /usr/local/bin/*

COPY entrypoint.bash /

ENTRYPOINT [ "/entrypoint.bash" ]
