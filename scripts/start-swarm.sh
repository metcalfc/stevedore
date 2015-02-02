#!/bin/bash

check_landrush () {
  if [ $(vagrant landrush status | grep running -c) -eq 0 ]; then
    vagrant landrush restart > /dev/null 2>&1
  fi
}

get_ip () {
  dig +short $1 -p 10053 @localhost
}

SWARM_HOSTS=''
for HOST in $(vagrant status | grep running | awk {'print $1'}); do
  SWARM_HOSTS="$SWARM_HOSTS,$(get_ip $HOST):2375"
done

IP=$(dig +short swarm01.docker.vm -p 10053 @localhost)

check_landrush

ssh swarm01 sudo /vagrant/scripts/swarm-manager.sh ${SWARM_HOSTS#,} $IP

echo "unset DOCKER_CERT_PATH"
echo "unset DOCKER_TLS_VERIFY"
echo "export DOCKER_HOST=$IP:12345"
