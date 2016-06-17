export REPLICA_ID=$(printf "%012d" $(hostname | sed 's/[^0-9]//g'))

ucp () {
  docker run --rm -it --name ucp   \
    -v /var/run/docker.sock:/var/run/docker.sock  \
    -v /vagrant/ca-backup.tar:/backup.tar  \
    docker/ucp:1.1.0-rc5 \
    "$@"
}

dtr () {
  docker run -it --rm   docker/dtr:2.0.0 "$@"
}

network-bounce-dtr-containers () {
  docker rename dtr-rethinkdb-${REPLICA_ID} tmp-dtr-rethinkdb-${REPLICA_ID}
  docker network disconnect -f dtr-ol dtr-rethinkdb-${REPLICA_ID}
  docker rename tmp-dtr-rethinkdb-${REPLICA_ID} dtr-rethinkdb-${REPLICA_ID}
  docker network connect dtr-ol dtr-rethinkdb-${REPLICA_ID}
  docker start dtr-rethinkdb-${REPLICA_ID}

  docker rename dtr-etcd-${REPLICA_ID} tmp-dtr-etcd-${REPLICA_ID}
  docker network disconnect -f dtr-ol dtr-etcd-${REPLICA_ID}
  docker rename tmp-dtr-etcd-${REPLICA_ID} dtr-etcd-${REPLICA_ID}
  docker network connect dtr-ol dtr-etcd-${REPLICA_ID}
  docker start dtr-etcd-${REPLICA_ID}
}

dtr-etcd () {
  docker run --rm -v dtr-ca-$REPLICA_ID:/ca \
    --net dtr-br -it --entrypoint /etcdctl \
    quay.io/coreos/etcd:v2.2.4 \
    --endpoint https://dtr-etcd-$REPLICA_ID.dtr-br:2379 \
    --ca-file /ca/etcd/cert.pem \
    --key-file /ca/etcd-client/key.pem \
    --cert-file /ca/etcd-client/cert.pem \
    "$@"
}

ucp-etcd () {
  docker exec -it ucp-kv etcdctl \
    --endpoint https://127.0.0.1:2379 \
    --ca-file /etc/docker/ssl/ca.pem \
    --cert-file /etc/docker/ssl/cert.pem \
    --key-file /etc/docker/ssl/key.pem \
    "$@"
}

dtr-gc () {
  curl -X POST -u admin:orca -H "Content-Type: application/json" \
   "https://${1}/api/v0/admin/jobs" -d "{ \"job\" : \"registryGC\"}"
}
