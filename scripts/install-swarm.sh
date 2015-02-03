#!/bin/bash

export GOPATH=~/go
export SWARM_DIR=$GOPATH/src/github.com/docker/swarm

SWARM_GIT_REF='HEAD'
SWARM_GIT_REPO='https://github.com/docker/swarm.git'
SWARM_BINARY=''
BUILD_HOST=''

for i in "$@"
do
case $i in
    SWARM_GIT_REF=*)
    SWARM_GIT_REF="${i#*=}"
    shift
    ;;
    SWARM_GIT_REPO=*)
    SWARM_GIT_REPO="${i#*=}"
    shift
    ;;
    SWARM_BINARY=*)
    SWARM_BINARY="${i#*=}"
    shift
    ;;
    BUILD_HOST=*)
    BUILD_HOST="${i#*=}"
    shift
    ;;
esac
done

echo "SWARM_GIT_REF  = ${SWARM_GIT_REF}"
echo "SWARM_GIT_REPO = ${SWARM_GIT_REPO}"
echo "SWARM_BINARY   = ${SWARM_BINARY}"
echo "BUILD_HOST     = ${BUILD_HOST}"

installSwarm () {
  pkill -9 swarm  || true

  echo "Checking for a binary release"
  if [[ ! -z "$SWARM_BINARY" ]]; then
    if [ "$HOSTNAME" = "$BUILD_HOST" ]; then
      $curl "$SWARM_BINARY" > /vagrant/.vagrant/swarm
      chmod +x /vagrant/.vagrant/swarm
    fi

  else

    if [ "$HOSTNAME" = "$BUILD_HOST" ]; then

      if cd "$SWARM_DIR"; then
        git fetch
      else
        git clone "$SWARM_GIT_REPO" "$SWARM_DIR"
      fi

      pushd "$SWARM_DIR"
      git log -1
      docker build -t swarm .
      docker run  --rm -v /vagrant:/vagrant --entrypoint='/bin/bash' swarm -c '/bin/cp /go/bin/swarm /vagrant/.vagrant/'
      popd
    fi
  fi

  echo "Installing swarm"
  cp /vagrant/.vagrant/swarm /usr/local/bin

}

if [[ ! -e /vagrant/.vagrant/swarm ]]; then
  installSwarm
fi
