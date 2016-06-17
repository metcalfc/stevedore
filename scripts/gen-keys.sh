#!/bin/bash

NAME=""
IP=""
CNAMES=()

for i in "$@"
do
case $i in
    NAME=*)
    NAME="${i#*=}"
    shift
    ;;
    IP=*)
    IP="${i#*=}"
    shift
    ;;
    CNAME=*)
    echo "CNAME ${i#*=}"
    CNAMES+=("${i#*=}")
    shift
    ;;
esac
done

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# We want to run from Stevedore's root
cd $DIR/..

if [[ ${#CNAMES[@]} -ne 0 ]]; then
  CNAME_SAN=$(printf -- "+%s " "${CNAMES[@]}")
fi

if [[ ! -f ./etc/ssl/${NAME}.cnf ]]; then
  docker run --rm -v $PWD/etc:/certified/etc \
    --entrypoint /usr/local/bin/certified \
    -v ~/.gitconfig:/root/.gitconfig \
    metcalfc/certified:latest \
    CN="${NAME}" +"*.${NAME}" +"${NAME%%.*}" +"${IP}" ${CNAME_SAN}
fi

# We need the intermediate CA in the cert
cat  ${PWD}/etc/ssl/certs/ca.crt >> ${PWD}/etc/ssl/certs/${NAME}.crt
# We need the intermediate CA appended with the root-ca
# cat  ${PWD}/etc/ssl/certs/ca.crt      >  ${PWD}/etc/ca.pem
cat  ${PWD}/etc/ssl/certs/root-ca.crt > ${PWD}/etc/ca.pem

# Generate a java keystore for things like Jenkins
openssl pkcs12 -password pass:docker -inkey ${PWD}/etc/ssl/private/${NAME}.key \
  -in ${PWD}/etc/ssl/certs/${NAME}.crt -export -out ${PWD}/etc/${NAME}.pkcs12

keytool -importkeystore  -noprompt -srckeystore ${PWD}/etc/${NAME}.pkcs12 \
  -srcstoretype pkcs12 -destkeystore ${PWD}/etc/${NAME}.jks  \
  -srcstorepass docker -deststorepass docker

keytool -import -noprompt -trustcacerts -file ${PWD}/etc/ca.pem \
   -keystore ${PWD}/etc/${NAME}.jks  \
  -keypass docker -storepass docker -alias docker
