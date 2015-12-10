#!/bin/bash

NAME=${1:?"Must specify a hostname"}

if [[ "$HOSTNAME" != "$NAME" ]]; then
  echo "${NAME}" > /etc/hostname
  hostname "${NAME}"
  echo "Fixed Hostname"
else
  echo "Hostname ok"
fi
