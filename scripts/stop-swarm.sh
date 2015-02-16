#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SWARM_HOSTS="$("${DIR}/get-swarm-hosts.rb -m")"

IFS=","
for HOST in $SWARM_HOSTS; do
  vagrant ssh "${HOST%.docker.vm:12345}" -c "docker rm -f swarm-agent" > /dev/null 2>&1
done
