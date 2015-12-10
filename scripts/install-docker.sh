#!/bin/bash

DOCKER_OPTS=''
ENGINE_LABELS=()

for i in "$@"
do
case $i in
    DOCKER_OPTS=*)
    DOCKER_OPTS="${i#*=}"
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
  echo "Checking for a CS Install"
  case "$lsb_dist" in
  centos|redhat)

    echo "Installing rpm"
    rpm --import "https://pgp.mit.edu/pks/lookup?op=get&search=0xee6d536cf7dc86e2d7d56f59a178ac6c6238f52e"
    yum install -y yum-utils
    yum update -y
    yum-config-manager --add-repo 'https://packages.docker.com/1.9/yum/repo/main/centos/7'
    yum install -y docker-engine
    systemctl stop firewalld.service
    systemctl disable firewalld.service
    systemctl enable docker.service
    systemctl start docker.service
    ;;
  Ubuntu)

    export DEBIAN_FRONTEND=noninteractive
    # update the kernel
    apt-get update && apt-get upgrade -y && apt-get autoremove
    apt-get install -y apt-transport-https linux-image-extra-virtual

    echo "Installing deb"

    curl -s 'https://pgp.mit.edu/pks/lookup?op=get&search=0xee6d536cf7dc86e2d7d56f59a178ac6c6238f52e' \
      | apt-key add --import
    echo "deb https://packages.docker.com/1.9/apt/repo ubuntu-trusty main" > /etc/apt/sources.list.d/docker.list
    apt-get update && apt-get install -y docker-engine
    update-rc.d -f docker remove
    update-rc.d docker defaults 90
    ;;
  esac

  usermod -aG docker vagrant

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

  mkdir -p /data
  cp -r /vagrant/etc /data
  SSL_OPTS="--tlsverify --tlscacert=/data/etc/ca.pem --tlscert=/data/etc/ssl/certs/$(hostname -f).crt --tlskey=/data/etc/ssl/private/$(hostname -f).key"

  LINE="${DOCKER_OPTS_VAR}='${DOCKER_OPTS} ${SSL_OPTS} -H unix:///var/run/docker.sock -H 0.0.0.0:2376 ${LABELS}'"

  touch $DOCKER_CONFIG
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

installJq () {
    $curl https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 > /usr/local/bin/jq
    chmod 0755 /usr/local/bin/jq
}

if [[ ${#ENGINE_LABELS[@]} -ne 0 ]]; then
  printf "%s" "ENGINE_LABELS         = "
  printf -- "--label %s " "${ENGINE_LABELS[@]}"
  printf "%s\n" ""
fi

command_exists dig || installDig
command_exists jq  || installJq
installDocker
installCA
updateDockerConfig
