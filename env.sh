DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

make-dtr-bundle () {
    mkdir -p $DIR/dtr
    cp $DIR/etc/ca.pem $DIR/dtr/ca.pem
    cp $DIR/etc/ssl/private/dtr.docker.vm.key $DIR/dtr/key.pem
    cp $DIR/etc/ssl/certs/dtr.docker.vm.crt $DIR/dtr/cert.pem
}
use-dtr () {
    export DOCKER_HOST=tcp://dtr.docker.vm:2376
    export DOCKER_CERT_PATH=$DIR/dtr
    export DOCKER_TLS_VERIFY=1
}
use-ucp () {
    export DOCKER_HOST=tcp://ducp.docker.vm:443
    export DOCKER_CERT_PATH=$DIR/ducp
    export DOCKER_TLS_VERIFY=1
}
