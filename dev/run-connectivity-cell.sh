#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

engine="${1:?engine required}"
path="${2:?path required}"
export QV_MATRIX_ENGINE="$engine" QV_MATRIX_PATH="$path"
tags=integration
[[ "$engine" != duckdb ]] || tags=integration,duckdb
if [[ "$engine" == sqlite || "$engine" == duckdb ]]; then
  if [[ "$path" != direct ]]; then
    echo "$engine / $path: n/a (file engine)"
    [[ -z "${GITHUB_STEP_SUMMARY:-}" ]] || echo "$engine / $path: n/a (file engine)" >>"$GITHUB_STEP_SUMMARY"
    exit 0
  fi
else
  compose=(docker compose -p "queravue-matrix-$engine-$path" -f dev/docker-compose.yml -f dev/docker-compose.matrix.yml)
  service="$engine"
  services=("$service")
  case "$path" in
    direct)
      ;;
    tls)
      compose+=(-f dev/docker-compose.matrix-tls.yml)
      case "$engine" in
        postgres|mysql|mongo|clickhouse) service="$engine-tls" ;;
      esac
      services=("$service")
      dev/tls/gen.sh
      if [[ "$engine" == oracle ]]; then dev/tls/oracle/wallet.sh; fi
      ;;
    ssh)
      compose+=(-f dev/docker-compose.matrix-ssh.yml)
      services+=(ssh-bastion)
      dev/tls/gen.sh
      ;;
    *)
      echo "Unknown path: $path" >&2
      exit 1
      ;;
  esac
  cleanup() {
    local code=$?
    if ((code != 0)); then "${compose[@]}" logs --tail 80 "${services[@]}" || true; fi
    "${compose[@]}" --profile '*' down -v || true
    exit "$code"
  }
  trap cleanup EXIT
  "${compose[@]}" up -d --wait --wait-timeout 300 "${services[@]}"
  if [[ "$path" == ssh ]]; then
    published="$("${compose[@]}" ps --format json "$service" | jq -r '.Publishers[]? | select(.PublishedPort > 0) | .PublishedPort')"
    if [[ -n "$published" ]]; then
      echo "SSH cell database has a published port" >&2
      exit 1
    fi
    QV_MATRIX_SSH_PORT="$("${compose[@]}" port ssh-bastion 2222)"
    export QV_MATRIX_SSH_PORT="${QV_MATRIX_SSH_PORT##*:}"
  else
    case "$service" in
      postgres|postgres-tls) container_port=5432 ;;
      mysql|mysql-tls|mariadb) container_port=3306 ;;
      cockroachdb) container_port=26257 ;;
      tidb) container_port=4000 ;;
      mssql) container_port=1433 ;;
      oracle) container_port=1521; [[ "$path" != tls ]] || container_port=2484 ;;
      clickhouse) container_port=9000 ;;
      clickhouse-tls) container_port=9440 ;;
      mongo) container_port="${QV_MATRIX_MONGO_PORT:-27017}" ;;
      mongo-tls) container_port=27019 ;;
      documentdb) container_port=10260 ;;
      redis|valkey) container_port=6379 ;;
      redis-cluster) container_port=7100 ;;
    esac
    QV_MATRIX_PORT="$("${compose[@]}" port "$service" "$container_port")"
    export QV_MATRIX_PORT="${QV_MATRIX_PORT##*:}"
  fi
fi

tests='^TestConnectivityMatrix$'
if [[ "$engine/$path" == postgres/ssh ]]; then
  tests='^Test(ConnectivityMatrix|SSHKeyAndAgentAuth)$'
fi
(cd core && go test -count=1 -v -tags "$tags" -run "$tests" ./internal/netcells)
