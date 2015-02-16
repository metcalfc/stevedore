#!/bin/bash

SWARM_HOSTS=${1:?"Must specify one or more swarm hosts"}

docker rm -f swarm-agent 2&>/dev/null

SSL_OPTS="--tlsverify --tlscacert=/vagrant/etc/ssl/certs/root-ca.crt --tlscert=/vagrant/etc/ssl/certs/$(hostname -f).crt --tlskey=/vagrant/etc/ssl/private/$(hostname -f).key"

docker run -d -p 12345:12345 --name swarm-agent --restart=always -v /vagrant:/vagrant:ro swarm:latest --debug manage ${SWARM_HOSTS} ${SSL_OPTS} -H tcp://0.0.0.0:12345
