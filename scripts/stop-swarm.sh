#!/bin/bash

for i in $(vagrant status | grep running | awk {'print $1'}); do
  ssh "$i" "sudo pkill -9 swarm " > /dev/null 2>&1
done
