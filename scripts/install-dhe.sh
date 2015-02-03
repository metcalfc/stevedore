#!/bin/bash

BUILD_HOST=''

for i in "$@"
do
case $i in
    BUILD_HOST=*)
    BUILD_HOST="${i#*=}"
    shift
    ;;
esac
done

if [[ $(docker ps  | grep 'dockerhubenterprise/admin-server' -c) -ne 1 ]]; then
  mkdir -p /usr/local/etc/dhe
  cp /vagrant/.dockercfg /usr/local/etc/dhe/
  cp /vagrant/.dockercfg /root/.dockercfg

  docker run -v /var/run/docker.sock:/var/run/docker.sock -e "deployId=${BUILD_HOST}" dockerhubenterprise/manager:latest install
fi
