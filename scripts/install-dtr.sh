#!/bin/bash

docker info

# Certs and configuration for notary
if ! docker volume inspect dtr-certs; then
    docker volume create --name dtr-certs
    docker run --name hold -v dtr-certs:/data tianon/true
    docker cp /vagrant/etc/ca.pem hold:/data/ca.pem
    docker cp /vagrant/etc/ssl/certs/$(hostname -f).crt hold:/data/cert.pem
    docker cp /vagrant/etc/ssl/private/$(hostname -f).key hold:/data/key.pem
    docker cp /vagrant/files/server-config.json hold:/data/server-config.json
    docker cp /vagrant/files/signer-config.json hold:/data/signer-config.json
fi

if ! docker volume inspect notary-mysql; then
    docker volume create --name notary-mysql
fi

if [[ $(docker ps  | grep 'dockerhubenterprise/admin-server' -c) -ne 1 ]]; then

  sudo bash -c "$(sudo docker run docker/trusted-registry install)"

  rm /usr/local/etc/dtr/ssl/server.pem
  cat /vagrant/etc/ssl/private/$(hostname -f).key \
      /vagrant/etc/ssl/certs/$(hostname -f).crt >> \
      /usr/local/etc/dtr/ssl/server.pem
  mkdir -p /etc/docker/certs.d/$(hostname -f)
  cp /vagrant/etc/ca.pem /etc/docker/certs.d/$(hostname -f)/ca.pem

  # hub.yaml, garant,yaml, storage.yaml
  cp /vagrant/files/* /usr/local/etc/dtr/

  cp /vagrant/etc/license.json /usr/local/etc/dtr/license.json

  sudo bash -c "$(sudo docker run docker/trusted-registry restart)"

fi

if [[ $(docker ps  | grep 'notary' -c) -ne 3 ]]; then
    cp /vagrant/files/docker-compose.yml /vagrant/src/notary
    cd /vagrant/src/notary|| echo "Couldn't cd to /vagrant/src/notary"
#    docker-compose up -d
fi
