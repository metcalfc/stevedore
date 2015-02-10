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

  docker run -v /var/run/docker.sock:/var/run/docker.sock \
    -e "deployId=$(hostname -f)" dockerhubenterprise/manager:latest install

  rm /usr/local/etc/dhe/ssl/server.pem
  cat /vagrant/etc/ssl/private/$(hostname -f).key \
      /vagrant/etc/ssl/certs/$(hostname -f).crt >> \
      /usr/local/etc/dhe/ssl/server.pem
  mkdir -p /etc/docker/certs.d/$(hostname -f)
  cp /vagrant/etc/ca.pem /etc/docker/certs.d/$(hostname -f)/ca.pem
  docker restart docker_hub_enterprise_load_balancer

fi
