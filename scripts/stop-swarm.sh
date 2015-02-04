#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SWARM_HOSTS="$("${DIR}/get-swarm-hosts.rb")"

IFS=","
for HOST in $SWARM_HOSTS; do
  ssh "${HOST%.docker.vm:2375}" "sudo pkill -9 swarm " > /dev/null 2>&1
done
