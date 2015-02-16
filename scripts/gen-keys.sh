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
cat  ${PWD}/etc/ssl/certs/ca.crt >> ${PWD}/etc/ssl/certs/${NAME}.crt

# Generate a java keystore for things like Jenkins
openssl pkcs12 -password pass:docker -inkey ${PWD}/etc/ssl/private/${NAME}.key \
  -in ${PWD}/etc/ssl/certs/${NAME}.crt -export -out ${PWD}/etc/${NAME}.pkcs12

keytool -importkeystore  -noprompt -srckeystore ${PWD}/etc/${NAME}.pkcs12 \
  -srcstoretype pkcs12 -destkeystore ${PWD}/etc/${NAME}.jks  \
  -srcstorepass docker -deststorepass docker

keytool -import -noprompt -trustcacerts -file ${PWD}/etc/ca.pem \
   -keystore ${PWD}/etc/${NAME}.jks  \
  -keypass docker -storepass docker -alias docker
