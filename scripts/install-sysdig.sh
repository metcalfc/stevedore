#!/bin/bash
apt-get -y install linux-headers-$(uname -r)
yum -y install kernel-devel-$(uname -r)
docker run --name sysdig-agent --privileged --net host --pid host -e ACCESS_KEY=2b5dce3e-1440-4d4e-9150-168856c5a96d [-e TAGS=[TAGS]] -v /var/run/docker.sock:/host/var/run/docker.sock -v /dev:/host/dev -v /proc:/host/proc:ro -v /boot:/host/boot:ro -v /lib/modules:/host/lib/modules:ro -v /usr:/host/usr:ro sysdig/agent
#Replace [TAGS] in the command above with a comma-separated list of TAG_NAME:TAG_VALUE (eg. role:webserver,location:europe)

