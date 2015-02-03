#!/bin/bash

export GOPATH=~/go
export COMPOSE_DIR=$GOPATH/src/github.com/docker/compose

COMPOSE_GIT_REF='HEAD'
COMPOSE_GIT_REPO='https://github.com/docker/fig.git'
COMPOSE_BINARY=''
BUILD_HOST=''

for i in "$@"
do
case $i in
    COMPOSE_GIT_REF=*)
    COMPOSE_GIT_REF="${i#*=}"
    shift
    ;;
    COMPOSE_GIT_REPO=*)
    COMPOSE_GIT_REPO="${i#*=}"
    shift
    ;;
    COMPOSE_BINARY=*)
    COMPOSE_BINARY="${i#*=}"
    shift
    ;;
    BUILD_HOST=*)
    BUILD_HOST="${i#*=}"
    shift
    ;;
esac
done

echo "COMPOSE_GIT_REF  = ${COMPOSE_GIT_REF}"
echo "COMPOSE_GIT_REPO = ${COMPOSE_GIT_REPO}"
echo "COMPOSE_BINARY   = ${COMPOSE_BINARY}"
echo "BUILD_HOST       = ${BUILD_HOST}"

command_exists() {
  command -v "$@" > /dev/null 2>&1
}

curl=''
if command_exists curl; then
  curl='curl -sSL'
elif command_exists wget; then
  curl='wget -qO-'
elif command_exists busybox && busybox --list-modules | grep -q wget; then
  curl='busybox wget -qO-'
fi

installCompose () {
  echo "Installing compose on the host"

  # Has to be binary releases for now. We can't cross compile the OS X binary.
  echo "Checking for a binary release"
  if [[ ! -z "$COMPOSE_BINARY" ]]; then
    if [ "$HOSTNAME" = "$BUILD_HOST" ]; then
      if [[ ! -e /vagrant/bin/docker-compose ]]; then
        $curl "$COMPOSE_BINARY" > /vagrant/bin/docker-compose
        chmod +x /vagrant/bin/docker-compose
      fi
    fi
  fi
}

installCompose
