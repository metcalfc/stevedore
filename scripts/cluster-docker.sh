#!/bin/bash

CONTROLLER=$1
IP=$2

command_exists() {
  command -v "$@" > /dev/null 2>&1
}

# perform some very rudimentary platform detection
lsb_dist=''
if command_exists lsb_release; then
  lsb_dist="$(lsb_release -si)"
fi
if [ -z "$lsb_dist" ] && [ -r /etc/lsb-release ]; then
  lsb_dist="$(. /etc/lsb-release && echo "$DISTRIB_ID")"
fi
if [ -z "$lsb_dist" ] && [ -r /etc/debian_version ]; then
  lsb_dist='debian'
fi
if [ -z "$lsb_dist" ] && [ -r /etc/fedora-release ]; then
  lsb_dist='fedora'
fi
if [ -z "$lsb_dist" ] && [ -r /etc/os-release ]; then
  lsb_dist="$(. /etc/os-release && echo "$ID")"
fi

DOCKER_CONFIG='/etc/default/docker'

case "$lsb_dist" in
    centos|redhat)
    DOCKER_CONFIG='/etc/sysconfig/docker'
    ;;
esac

docker run --rm -it --name ucp \
    -v /var/run/docker.sock:/var/run/docker.sock \
    docker/ucp:1.0.1 engine-discovery \
    --controller $CONTROLLER \
    --host-address $IP \
    --debug \
    --update
