#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

check_landrush () {
  if [ $(vagrant landrush status | grep running -c) -eq 0 ]; then
    vagrant landrush restart > /dev/null 2>&1
  fi
}

SWARM_HOSTS="$("$DIR/get-swarm-hosts.rb")"
SWARM_MANAGER="$("$DIR/get-swarm-manager.rb")"

IFS=',' read -ra HOSTS <<< "${SWARM_HOSTS}"

check_landrush

vagrant ssh ${SWARM_MANAGER%.docker.vm:12345} \
  -c "sudo /vagrant/scripts/swarm-manager.sh ${SWARM_HOSTS}" \
  > /dev/null 2>&1

SWARM_MANAGER_IP="$(dig +short -p 10053 @localhost ${SWARM_MANAGER%:12345})"

echo "unset DOCKER_CERT_PATH"
echo "unset DOCKER_TLS_VERIFY"
echo "export DOCKER_HOST=${SWARM_MANAGER_IP}:12345"
