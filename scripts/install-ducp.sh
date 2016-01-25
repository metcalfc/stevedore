#!/bin/bash

DUCP_USERNAME=''
DUCP_PASSWORD=''

for i in "$@"
do
case $i in
    DUCP_USERNAME=*)
    DUCP_USERNAME="${i#*=}"
    shift
    ;;
    DUCP_PASSWORD=*)
    DUCP_PASSWORD="${i#*=}"
    shift
    ;;
esac
done

echo "Leading DUCP"

export REGISTRY_USERNAME=$(cat /vagrant/.dockercfg | /usr/local/bin/jq -r '.["https://index.docker.io/v1/"].auth' | base64 --decode | cut -d: -f1)
export REGISTRY_PASSWORD=$(cat /vagrant/.dockercfg | /usr/local/bin/jq -r '.["https://index.docker.io/v1/"].auth' | base64 --decode | cut -d: -f2)
export REGISTRY_EMAIL=$( cat /vagrant/.dockercfg | /usr/local/bin/jq -r '.["https://index.docker.io/v1/"].email')

docker volume create --name ucp-server-certs
docker run --name hold -v ucp-server-certs:/data tianon/true
docker cp /vagrant/etc/ca.pem hold:/data/ca.pem
docker cp /vagrant/etc/ssl/certs/$(hostname -f).crt hold:/data/cert.pem
docker cp /vagrant/etc/ssl/private/$(hostname -f).key hold:/data/key.pem

docker run --rm \
        --name ucp \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -e REGISTRY_USERNAME -e REGISTRY_PASSWORD -e REGISTRY_EMAIL \
        -e UCP_ADMIN_USER=${DUCP_USERNAME} \
        -e UCP_ADMIN_PASSWORD=${DUCP_PASSWORD} \
        docker/ucp:0.7.1 \
        install \
        --fresh-install \
        --debug \
        --san $(hostname -s) \
        --san $(hostname -f) \
        --host-address $(host $(hostname -f) | awk '/has address/ { print $4 ; exit }') \
        --external-ucp-ca \
        --swarm-port 3376
