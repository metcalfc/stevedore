#!/bin/bash

export GOPATH=~/go
export MACHINE_DIR=$GOPATH/src/github.com/docker/machine

MACHINE_GIT_REF='HEAD'
MACHINE_GIT_REPO='https://github.com/docker/machine.git'
MACHINE_BINARY=''
BUILD_HOST=''

for i in "$@"
do
case $i in
    MACHINE_GIT_REF=*)
    MACHINE_GIT_REF="${i#*=}"
    shift
    ;;
    MACHINE_GIT_REPO=*)
    MACHINE_GIT_REPO="${i#*=}"
    shift
    ;;
    MACHINE_BINARY=*)
    MACHINE_BINARY="${i#*=}"
    shift
    ;;
    BUILD_HOST=*)
    BUILD_HOST="${i#*=}"
    shift
    ;;
esac
done

echo "MACHINE_GIT_REF  = ${MACHINE_GIT_REF}"
echo "MACHINE_GIT_REPO = ${MACHINE_GIT_REPO}"
echo "MACHINE_BINARY   = ${MACHINE_BINARY}"
echo "BUILD_HOST     = ${BUILD_HOST}"

installMachine () {
  echo "Installing machine on the host"

  echo "Checking for a binary release"
  if [[ ! -z "$MACHINE_BINARY" ]]; then
    if [ "$HOSTNAME" = "$BUILD_HOST" ]; then
      if [[ ! -e /vagrant/bin/docker-machine ]]; then
        $curl "$MACHINE_BINARY" > /vagrant/bin/machine
        chmod +x /vagrant/bin/machine
      fi
    fi

  else

    if [ "$HOSTNAME" = "$BUILD_HOST" ]; then

      if cd "$MACHINE_DIR"; then
        git fetch
      else
        git clone "$MACHINE_GIT_REPO" "$MACHINE_DIR"
      fi

      pushd "$MACHINE_DIR"
        git log -1
        ./script/build -osarch="darwin/amd64"
        if [[ -e ./machine_darwin_amd64 ]]; then
          cp ./machine_darwin_amd64 /vagrant/bin/docker-machine
        else
          cp ./docker-machine_darwin-amd64 /vagrant/bin/docker-machine
        fi
      popd
    fi
  fi
}

installMachine
