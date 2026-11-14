#!/usr/bin/env bash
set -euo pipefail
cli=()
tls=()
if [[ "${MATRIX_TLS:-}" == 1 ]]; then
  cli=(--tls --cacert /tls/ca.pem)
  tls=(--tls-cluster yes --tls-auth-clients no --tls-cert-file /tls/redis-cluster.crt
       --tls-key-file /tls/redis-cluster.key --tls-ca-cert-file /tls/ca.pem)
fi
mkdir -p /tmp/cluster
for port in 7100 7101 7102; do
  listen=(--port "$port")
  if (("${#tls[@]}")); then listen=(--port 0 --tls-port "$port"); fi
  redis-server "${listen[@]}" "${tls[@]}" --cluster-enabled yes \
    --cluster-announce-hostname "$MATRIX_CLUSTER_HOST" --cluster-preferred-endpoint-type hostname \
    --cluster-config-file "/tmp/cluster/$port.conf" --save '' --appendonly no &
done
trap 'kill $(jobs -p)' TERM INT
for port in 7100 7101 7102; do
  until redis-cli "${cli[@]}" -p "$port" ping 2>/dev/null | grep -q PONG; do sleep 1; done
done
redis-cli "${cli[@]}" --cluster create 127.0.0.1:7100 127.0.0.1:7101 127.0.0.1:7102 --cluster-yes
wait -n
