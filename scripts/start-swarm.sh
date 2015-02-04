#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

check_landrush () {
  if [ $(vagrant landrush status | grep running -c) -eq 0 ]; then
    vagrant landrush restart > /dev/null 2>&1
  fi
}

SWARM_HOSTS="$("$DIR/get-swarm-hosts.rb")"

IFS=',' read -ra HOSTS <<< "${SWARM_HOSTS}"
SWARM_MANAGER="${HOSTS[0]%:2375}"

check_landrush

ssh "${SWARM_MANAGER%.docker.vm}" sudo /vagrant/scripts/swarm-manager.sh "${SWARM_HOSTS}"

echo "unset DOCKER_CERT_PATH"
echo "unset DOCKER_TLS_VERIFY"
echo "export DOCKER_HOST=${SWARM_MANAGER}:12345"
