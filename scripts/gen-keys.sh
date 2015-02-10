#!/bin/bash

NAME=${1:?"Must specify a hostname"}
IP=${2:?"Must specify a ip address"}

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# We want to run from Stevedore's root
cd $DIR/..

if [[ ! -f ./etc/ssl/${NAME}.cnf ]]; then
  docker run --rm -v $PWD/etc:/certified/etc \
    --entrypoint /usr/local/bin/certified \
    -v ~/.gitconfig:/root/.gitconfig \
    metcalfc/certified:latest \
    CN="${NAME}" +"*.${NAME}" +"${IP}"
fi

# We need the intermediate CA in the cert
cat  ./etc/ssl/certs/ca.crt >> ./etc/ssl/certs/${NAME}.crt
