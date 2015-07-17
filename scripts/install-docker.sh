#!/bin/bash

export GOPATH=~/go
export DOCKER_DIR=$GOPATH/src/github.com/docker/docker

DOCKER_GIT_REF=''
DOCKER_GIT_REPO=''
DOCKER_BINARY=''
PACKAGECLOUD_TOKEN=''
DOCKER_OPTS=''
ENGINE_LABELS=()

for i in "$@"
do
case $i in
    PACKAGECLOUD_TOKEN=*)
    PACKAGECLOUD_TOKEN="${i#*=}"
    shift
    ;;
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
echo $lsb_dist
  echo "Checking for a CS Install"
  if [[ ! -z "$PACKAGECLOUD_TOKEN" ]]; then
    export PACKAGECLOUD_TOKEN
    case "$lsb_dist" in
    centos|redhat)
      echo "Installing rpm"
      /vagrant/scripts/docker-cs-engine-rpm.sh
      yum install -y docker-engine-cs
      systemctl stop firewalld.service
      systemctl disable firewalld.service
      systemctl start docker.service
      systemctl enable docker.service
      ;;
    Ubuntu|debian)
      echo "Installing deb"
      /vagrant/scripts/docker-cs-engine-deb.sh
      apt-get install -y docker-engine-cs
      ;;
    esac

    usermod -aG docker vagrant

  fi

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

  SSL_OPTS="--tlsverify --tlscacert=/vagrant/etc/ca.pem --tlscert=/vagrant/etc/ssl/certs/$(hostname -f).crt --tlskey=/vagrant/etc/ssl/private/$(hostname -f).key"

  LINE="${DOCKER_OPTS_VAR}='${DOCKER_OPTS} ${SSL_OPTS} -H unix:///var/run/docker.sock -H 0.0.0.0:2376 ${LABELS}'"

  if ! grep -qF "$LINE" $DOCKER_CONFIG ; then
    sed -i -- "/^${DOCKER_OPTS_VAR}=/d" $DOCKER_CONFIG
    echo "$LINE" >> $DOCKER_CONFIG

    #kill any existing Docker ID
    rm -f /etc/docker/key.json

    service docker restart
  fi
}

installCA() {

  CA_DEST=/usr/local/share/ca-certificates
  CA_UPDATE_TOOL="update-ca-certificates"

  case "$lsb_dist" in
  centos|redhat)
    CA_DEST=/etc/pki/ca-trust/source/anchors
    CA_UPDATE_TOOL="update-ca-trust"
    ;;
  esac

  mkdir -p /etc/docker/certs.d/enterprise.docker.vm

  cp /vagrant/etc/ca.pem $CA_DEST/docker-ca.crt
  cp /vagrant/etc/ca.pem /etc/docker/certs.d/enterprise.docker.vm/ca.pem

  $CA_UPDATE_TOOL
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

echo "DOCKER_GIT_REF     = ${DOCKER_GIT_REF}"
echo "DOCKER_GIT_REPO    = ${DOCKER_GIT_REPO}"
echo "DOCKER_BINARY      = ${DOCKER_BINARY}"
echo "PACKAGECLOUD_TOKEN = ${PACKAGECLOUD_TOKEN}"

if [[ ${#ENGINE_LABELS[@]} -ne 0 ]]; then
  printf "%s" "ENGINE_LABELS         = "
  printf -- "--label %s " "${ENGINE_LABELS[@]}"
  printf "%s\n" ""
fi

command_exists dig || installDig

installDocker
installCA
updateDockerConfig
