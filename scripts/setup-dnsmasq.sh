#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

DNSMASQ_DOMAIN='docker.vm'
DNSMASQ_IFACE='vboxnet1'
VBOX_HOST_IP='192.168.99.1'
VBOX_NETMASK='255.255.255.0'

if ! which VBoxManage >/dev/null; then
  echo "VBoxManage command not found, is VirtualBox installed?"
  exit 1
fi

if ! which dnsmasq >/dev/null; then
  echo "dnsmasq command not found, is dnsmasq installed?"
  echo "Install with 'brew install dnsmasq'"
  exit 1
fi

# Check that the DNSMASQ_IFACE exists
if ! VBoxManage list hostonlyifs | grep -E 'Name:\s+'$DNSMASQ_IFACE > /dev/null; then
  echo "Host-only interface not found: $DNSMASQ_IFACE, create with 'VBoxManage hostonlyif create'"
  # Note that VirtualBox only supports interfaces with names vboxnet0, vboxnet1, ...
  # which it creates sequentially, therefore its difficult to autmatically create the required
  # interface in a script, rather bail out here let the user do it manually...
  exit 1
fi

# Disable VirtualBox built-in DHCP server
VBoxManage dhcpserver remove --ifname "$DNSMASQ_IFACE" 2>&1 | grep -v 'DHCP server does not exist'

# Configure the host IP address
VBoxManage hostonlyif ipconfig "$DNSMASQ_IFACE" --ip "$VBOX_HOST_IP" --netmask "$VBOX_NETMASK"

# Setup resolver to use dnsmasq for any *.docker.vm address
sudo mkdir -p /etc/resolver
echo "nameserver $VBOX_HOST_IP" | sudo tee "/etc/resolver/${DNSMASQ_DOMAIN}" > /dev/null

# Setup the dnsmasq service and start it at boot time
sudo cp "${DIR}/../files/dnsmasq.conf" /usr/local/etc/dnsmasq.conf
sudo brew services start dnsmasq
