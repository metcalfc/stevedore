#!/bin/bash

NFS_URI='mac.docker.vm:/Users/metcalfc/src/stevedore/nfs'
NFS_PATH='/data/dtr'

for i in "$@"
do
case $i in
    NFS_URI=*)
    NFS_URI="${i#*=}"
    shift
    ;;
    NFS_PATH=*)
    NFS_PATH="${i#*=}"
    shift
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

setupFstab () {

  MOUNT_FILE=/etc/fstab
  MOUNT_LINE=$1

  if [ -z $(grep "$MOUNT_LINE" "$MOUNT_FILE")  ]; then
      echo "Updating /etc/fstab"
      echo "${MOUNT_LINE}" >> /etc/fstab
  else
      echo "Found the URI in /etc/fstab"
  fi

}

installNFS() {

  REPLICA_ID="$(printf "%012d" "$(hostname | sed 's/[^0-9]//g')")"
  NFS_LINE="${NFS_URI} ${NFS_PATH} nfs rw,relatime,vers=3,rsize=65536,wsize=65536,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountvers=3,local_lock=none 0 0"
  BIND_PATH=/var/lib/docker/volumes/dtr-registry-${REPLICA_ID}/_data
  BIND_LINE="/data/dtr ${BIND_PATH} none bind 0 0"

  case "$lsb_dist" in
  centos|redhat)

    yum install -y nfs-utils

    systemctl enable rpcbind
    systemctl enable nfs-server
    systemctl enable nfs-lock
    systemctl enable nfs-idmap
    systemctl start rpcbind
    systemctl start nfs-server
    systemctl start nfs-lock
    systemctl start nfs-idmap

    ;;
  Ubuntu)

    apt-get install -y nfs-common
    ;;
  esac

  setupFstab "${NFS_LINE}"
  mkdir -p ${NFS_PATH}
  mount ${NFS_PATH}

  setupFstab "${BIND_LINE}"
  mkdir -p ${BIND_PATH}
  mount ${BIND_PATH}
}

installNFS
