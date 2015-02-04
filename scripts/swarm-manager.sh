#!/bin/bash

SWARM_HOSTS=${1:?"Must specify one or more swarm hosts"}

PID_FILE=/var/run/swarm-manager.pid

touch $PID_FILE

if [[ -f /proc/$(cat $PID_FILE)/status ]]; then
  killall swarm
fi

nohup swarm --debug manage $SWARM_HOSTS  \
  -H tcp://0.0.0.0:12345 > /var/log/swarm-manager.log 2>&1 & \
  echo $! > /var/run/swarm-manager.pid
