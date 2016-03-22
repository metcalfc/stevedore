DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export STEVEDORE_ROOT=$DIR

make-dtr-bundle () {
    mkdir -p $DIR/dtr
    cp $DIR/etc/ca.pem $DIR/dtr/ca.pem
    cp $DIR/etc/ssl/private/dtr.docker.vm.key $DIR/dtr/key.pem
    cp $DIR/etc/ssl/certs/dtr.docker.vm.crt $DIR/dtr/cert.pem
}

make-dev-bundle () {
    mkdir -p $DIR/dev
    cp $DIR/etc/ca.pem $DIR/dev/ca.pem
    cp $DIR/etc/ssl/private/dev.docker.vm.key $DIR/dev/key.pem
    cp $DIR/etc/ssl/certs/dev.docker.vm.crt $DIR/dev/cert.pem
}

make-ucp-bundle () {
    DUCP="${1:-ducp.docker.vm}"
    USER_NAME="${1:-admin}"
    PASSWD="${1:-orca}"
    TMPFILE=$(mktemp -d "/tmp/${DUCP}.XXXXXX") || exit 1
    JSON="{\"username\":\"${USER_NAME}\",\"password\":\"${PASSWD}\"}"
    AUTHTOKEN=$(curl -sk -d "${JSON}" "https://${DUCP}/auth/login" | jq -r .auth_token)
    curl -k -H "Authorization: Bearer $AUTHTOKEN" "https://${DUCP}/api/clientbundle" -o ${TMPFILE}/bundle.zip
    unzip  "${TMPFILE}/bundle.zip" -d "${DIR}/ducp"
    rm -rf "${TMPFILE}" || echo "Couldn't delete ${TMPFILE}"
}

use-dtr () {
    export DOCKER_HOST=tcp://dtr.docker.vm:2376
    export DOCKER_CERT_PATH=$DIR/dtr
    export DOCKER_TLS_VERIFY=1
}

use-dev () {
    export DOCKER_HOST=tcp://dev.docker.vm:2376
    export DOCKER_CERT_PATH=$DIR/dev
    export DOCKER_TLS_VERIFY=1
}

use-ucp () {
    export DOCKER_HOST=tcp://ducp.docker.vm:443
    export DOCKER_CERT_PATH=$DIR/ducp
    export DOCKER_TLS_VERIFY=1
}

bounce-ucp () {
    vagrant ssh ducp -c "docker restart ucp-controller"
}
