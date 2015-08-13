#!/bin/bash

set -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

cd $DIR/..

if [ $(docker ps > /dev/null 2>&1; echo $?) -ne 0 ]; then
  echo "error: unable to talk to b2d; please start b2d and set environment variables"
  exit 1
fi

mkdir -p ./etc

if [ -z "$PACKAGECLOUD_TOKEN" ]; then
    echo "Need to set PACKAGECLOUD_TOKEN"
    exit 1
fi

if [ -z "$DHE_LICENSE_FILE" ]; then
    echo "Need to set DHE_LICENSE_FILE"
    exit 1
fi

if [ -f $DHE_LICENSE_FILE ]; then
  cp $DHE_LICENSE_FILE ./etc/license.json
else
  echo "The DHE license file '$DHE_LICENSE_FILE' does not exist"
  exit 1
fi

docker run -it --rm -v $(pwd)/etc:/certified/etc \
-v ~/.gitconfig:/root/.gitconfig \
--entrypoint=/usr/local/bin/certified-ca \
metcalfc/certified:latest \
--root-password='docker' \
--root-crl-url=https://ca.enterprise.docker.vm:666/rootca.crl  \
--crl-url=https://ca.enterprise.docker.vm:666/ca.crl \
C="US" ST="CA" L="San Francisco" \
O="Docker" CN="Docker CA"

docker run -it --rm -v $(pwd)/etc:/certified/etc \
-v ~/.gitconfig:/root/.gitconfig \
--entrypoint=/usr/local/bin/certified \
metcalfc/certified:latest \
CN="client"

cat ./etc/ssl/certs/client.crt ./etc/ssl/certs/ca.crt >> ./etc/cert.pem

cp ./etc/ssl/private/client.key ./etc/key.pem

cat ./etc/ssl/certs/root-ca.crt ./etc/ssl/certs/ca.crt >> ./etc/ca.pem

./scripts/gen-ssl-keys.rb
