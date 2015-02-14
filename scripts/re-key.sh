#!/bin/bash

re-key-host () {
  ssh $1 "sudo rm -f /etc/docker/key.json && sudo service docker restart && sleep 1 && docker info | grep ID"
}

for i in $(vagrant status | grep running | awk {'print $1'}); do
  re-key-host $i
done
