#!/bin/bash

NAME=${1:?"Must specify a hostname"}

sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1

if [[ "$HOSTNAME" != "$NAME" ]]; then
  echo "${NAME}" > /etc/hostname
  hostname "${NAME}"
  echo "Fixed Hostname"
else
  echo "Hostname ok"
fi
