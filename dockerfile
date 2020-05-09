# This dockerfile is not to be deployed on heroku.
# It's for testing the scripts locally

# This page tells me that heroku's stack are based on ubuntu
# https://devcenter.heroku.com/articles/stack
FROM ubuntu:18.04

RUN apt-get update
RUN apt-get install -y sbcl openssl

RUN mkdir /heroku-buildpack-cl
WORKDIR /heroku-buildpack-cl

RUN mkdir /tmp/build_dir /tmp/cache_dir /tmp/config_var_dir

# TODO Setup some "config_var"

COPY . .

# RUN /heroku-buildpack-cl/bin/install-roswell.sh

ENTRYPOINT [ "/heroku-buildpack-cl/bin/compile", "/tmp/build_dir", "/tmp/cache_dir", "/tmp/env_dir" ]
 