#!/bin/bash

DUCP_HOSTNAME=''
DUCP_USERNAME=''
DUCP_PASSWORD=''
DUCP_VERSION='1.0.1'

for i in "$@"
do
case $i in
    DUCP_HOSTNAME=*)
    DUCP_HOSTNAME="${i#*=}"
    shift
    ;;
    DUCP_USERNAME=*)
    DUCP_USERNAME="${i#*=}"
    shift
    ;;
    DUCP_PASSWORD=*)
    DUCP_PASSWORD="${i#*=}"
    shift
    ;;
    DUCP_VERSION=*)
    DUCP_VERSION="${i#*=}"
    shift
    ;;
esac
done

echo "Joining DUCP - $DUCP_HOSTNAME $DUCP_USERNAME@$DUCP_PASSWORD"

export FDQN=$(hostname -f)
export IP=$(host ${FDQN} | awk '/has address/ { print $4 ; exit }')

FINGERPRINT=$(echo -n | openssl s_client -connect ${DUCP_HOSTNAME}:443 2> /dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | openssl x509 -noout -fingerprint -sha1 | cut -d= -f2)

echo "FINGERPRINT $FINGERPRINT"

docker run --rm \
        --name ucp \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -e UCP_ADMIN_USER=${DUCP_USERNAME} \
        -e UCP_ADMIN_PASSWORD=${DUCP_PASSWORD} \
        docker/ucp:${DUCP_VERSION} \
        join \
        --fresh-install \
        --url "https://${DUCP_HOSTNAME}" \
        --fingerprint "${FINGERPRINT}" \
        --san $(hostname -s) \
        --san $(hostname -f) \
        --host-address ${IP}
