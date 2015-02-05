#!/bin/bash

export GOPATH=~/go
export DOCKER_DIR=$GOPATH/src/github.com/docker/docker

DOCKER_GIT_REF=''
DOCKER_GIT_REPO=''
DOCKER_BINARY=''
DOCKER_OPTS=''
ENGINE_LABELS=()

for i in "$@"
do
case $i in
    DOCKER_GIT_REF=*)
    DOCKER_GIT_REF="${i#*=}"
    shift
    ;;
    DOCKER_GIT_REPO=*)
    DOCKER_GIT_REPO="${i#*=}"
    shift
    ;;
    DOCKER_BINARY=*)
    DOCKER_BINARY="${i#*=}"
    shift
    ;;
    DOCKER_OPTS=*)
    DOCKER_OPTS="${i#*=}"
    shift
    ;;
    BUILD_HOST=*)
    BUILD_HOST="${i#*=}"
    shift
    ;;
    *)
    ENGINE_LABELS+=("$i")
    ;;
esac
done

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

# perform some very rudimentary platform detection
lsb_dist=''
if command_exists lsb_release; then
  lsb_dist="$(lsb_release -si)"
fi
if [ -z "$lsb_dist" ] && [ -r /etc/lsb-release ]; then
  lsb_dist="$(. /etc/lsb-release && echo "$DISTRIB_ID")"
fi
if [ -z "$lsb_dist" ] && [ -r /etc/debian_version ]; then
  lsb_dist='debian'
fi
if [ -z "$lsb_dist" ] && [ -r /etc/fedora-release ]; then
  lsb_dist='fedora'
fi
if [ -z "$lsb_dist" ] && [ -r /etc/os-release ]; then
  lsb_dist="$(. /etc/os-release && echo "$ID")"
fi

installDocker() {
  if [[ ! -z "$DOCKER_GIT_REF" ]]; then

    if [ "$HOSTNAME" = "$BUILD_HOST" ]; then

      if cd "$DOCKER_DIR"; then
        git fetch;
      else
        git clone "$DOCKER_GIT_REPO" "$DOCKER_DIR"
      fi

      pushd "$DOCKER_DIR"
        git log -1
        make binary
        cp $(find $PWD/bundles -name docker) /vagrant/.vagrant/docker
        chmod +x /vagrant/.vagrant/docker
      popd
    fi

    service docker stop
    cp /vagrant/.vagrant/docker /usr/bin/docker
    docker --version
    service docker start
  fi

  echo "Checking for a binary release"
  if [[ ! -z "$DOCKER_BINARY" ]]; then
    if [ "$HOSTNAME" = "$BUILD_HOST" ]; then
      if [[ ! -e /vagrant/.vagrant/docker ]]; then
        $curl "$DOCKER_BINARY" > /vagrant/.vagrant/docker
        chmod +x /vagrant/.vagrant/docker
      fi
    fi

    service docker stop
    cp /vagrant/.vagrant/docker /usr/bin/docker
    docker --version
    service docker start
  fi
}

updateDockerConfig () {
  DOCKER_OPTS_VAR='DOCKER_OPTS'
  DOCKER_CONFIG='/etc/default/docker'

  case "$lsb_dist" in
  centos|redhat)
    DOCKER_OPTS_VAR='OPTIONS'
    DOCKER_CONFIG='/etc/sysconfig/docker'
    DOCKER_OPTS="--selinux-enabled -H fd:// ${DOCKER_OPTS}"
    ;;
  esac

  if [[ ${#ENGINE_LABELS[@]} -ne 0 ]]; then
    LABELS=$(printf -- "--label %s " "${ENGINE_LABELS[@]}")
  fi

  LINE="${DOCKER_OPTS_VAR}='${DOCKER_OPTS} -H unix:///var/run/docker.sock -H 0.0.0.0:2375 ${LABELS}'"

  if ! grep -qF "$LINE" $DOCKER_CONFIG ; then
    sed -i -- '/^DOCKER_OPTS=/d' $DOCKER_CONFIG
    echo "$LINE" >> $DOCKER_CONFIG

    #kill any existing Docker ID
    rm -f /.docker/key.json

    service docker restart
  fi
}


installDig() {
  case "$lsb_dist" in
    centos|redhat)
    yum install -y bind-utils
    ;;
    ubuntu|debian)
    apt-get install -y dnsutils
    ;;
  esac
}

echo "DOCKER_GIT_REF  = ${DOCKER_GIT_REF}"
echo "DOCKER_GIT_REPO = ${DOCKER_GIT_REPO}"
echo "DOCKER_BINARY   = ${DOCKER_BINARY}"


if [[ ${#ENGINE_LABELS[@]} -ne 0 ]]; then
  printf "%s" "ENGINE_LABELS         = "
  printf -- "--label %s " "${ENGINE_LABELS[@]}"
  printf "%s\n" ""
fi


command_exists dig || installDig

updateDockerConfig

installDocker
