#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

check_landrush () {
  if [ $(vagrant landrush status | grep running -c) -eq 0 ]; then
    vagrant landrush restart > /dev/null 2>&1
  fi
}

SWARM_HOSTS="$("$DIR/get-swarm-hosts.rb")"

IFS=',' read -ra HOSTS <<< "${SWARM_HOSTS}"
SWARM_MANAGER="${HOSTS[0]%:2376}"

check_landrush

vagrant ssh swarm01 \
  -c "sudo /vagrant/scripts/swarm-manager.sh ${SWARM_HOSTS}" \
  > /dev/null 2>&1

echo "export DOCKER_TLS_VERIFY=yes"
echo "export DOCKER_CERT_PATH=$(dirname $DIR)/etc"
echo "export DOCKER_HOST=${SWARM_MANAGER}:12345"
