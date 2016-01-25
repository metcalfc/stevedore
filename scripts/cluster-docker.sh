#!/bin/bash

CONTROLLER=$1

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


CLUSTERING_OPTS=" --cluster-advertise eth1:12376 --cluster-store etcd://${CONTROLLER}:12379 --cluster-store-opt kv.cacertfile=/var/lib/docker/ucp_discovery_certs/ca.pem --cluster-store-opt kv.certfile=/var/lib/docker/ucp_discovery_certs/cert.pem --cluster-store-opt kv.keyfile=/var/lib/docker/ucp_discovery_certs/key.pem"
sed -i -- 's#-H 0.0.0.0:2376#-H 0.0.0.0:2376 '"${CLUSTERING_OPTS}"'#' $DOCKER_CONFIG
service docker restart
