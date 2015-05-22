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

docker info

if [[ $(docker ps  | grep 'dockerhubenterprise/admin-server' -c) -ne 1 ]]; then
  mkdir -p /usr/local/etc/dhe
  cp /vagrant/.dockercfg /usr/local/etc/dhe/
  cp /vagrant/.dockercfg /root/.dockercfg

  sudo bash -c "$(sudo docker run dockerhubenterprise/manager install)"

  rm /usr/local/etc/dhe/ssl/server.pem
  cat /vagrant/etc/ssl/private/$(hostname -f).key \
      /vagrant/etc/ssl/certs/$(hostname -f).crt >> \
      /usr/local/etc/dhe/ssl/server.pem
  mkdir -p /etc/docker/certs.d/$(hostname -f)
  cp /vagrant/etc/ca.pem /etc/docker/certs.d/$(hostname -f)/ca.pem

  cp /vagrant/files/garant.yml /usr/local/etc/dhe
  cp /vagrant/files/hub.yml /usr/local/etc/dhe
  cp /vagrant/files/storage.yml /usr/local/etc/dhe

  cp /vagrant/etc/license.json /usr/local/etc/dhe

  sudo bash -c "$(sudo docker run dockerhubenterprise/manager restart)"

fi
