#!/bin/bash

re-key-host () {
  vagrant ssh ${1} -c "sudo rm -f /etc/docker/key.json && sudo service docker restart && sleep 1 && docker info | grep ID"
}

for i in $(vagrant status | grep running | awk {'print $1'}); do
  re-key-host ${i}
done
