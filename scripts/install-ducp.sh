#!/bin/bash

DUCP_USERNAME=''
DUCP_PASSWORD=''
DUCP_VERSION='1.0.3'

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
    DUCP_VERSION=*)
    DUCP_VERSION="${i#*=}"
    shift
    ;;
esac
done

echo "Leading DUCP"

docker volume create --name ucp-controller-server-certs
docker run --name hold -v ucp-controller-server-certs:/data tianon/true
docker cp /vagrant/etc/ca.pem hold:/data/ca.pem
docker cp /vagrant/etc/ssl/certs/$(hostname -f).crt hold:/data/cert.pem
docker cp /vagrant/etc/ssl/private/$(hostname -f).key hold:/data/key.pem

docker run --rm \
        --name ucp \
        -v /var/run/docker.sock:/var/run/docker.sock \
		-v /vagrant/etc/license.lic:/docker_subscription.lic \
        -e UCP_ADMIN_USER=${DUCP_USERNAME} \
        -e UCP_ADMIN_PASSWORD=${DUCP_PASSWORD} \
        docker/ucp:${DUCP_VERSION} \
        install \
        --fresh-install \
        --debug \
        --san $(hostname -s) \
        --san $(hostname -f) \
        --host-address $(host $(hostname -f) | awk '/has address/ { print $4 ; exit }') \
        --external-ucp-ca \
        --swarm-port 3376
