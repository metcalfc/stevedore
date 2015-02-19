#!/bin/bash

set -e

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

cd $DIR/..

if [ $(docker ps > /dev/null 2>&1; echo $?) -ne 0 ]; then
  echo "error: unable to talk to b2d; please start b2d and set environment variables"
  exit 1
fi

mkdir -p ./etc

docker run -it --rm -v $(pwd)/etc:/certified/etc \
-v ~/.gitconfig:/root/.gitconfig \
--entrypoint=/usr/local/bin/certified-ca \
metcalfc/certified:latest \
--root-password='docker' \
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
