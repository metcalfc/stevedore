#!/bin/bash

SWARM_HOSTS=${1:?"Must specify one or more swarm hosts"}

docker rm -f swarm-agent 2&>/dev/null

docker run -d -p 12345:12345 --name swarm-agent --restart=always swarm --debug manage $SWARM_HOSTS -H tcp://0.0.0.0:12345
