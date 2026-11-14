#!/usr/bin/env bash
set -euo pipefail
install -d -m 700 /tmp/oracle-matrix-wallet
install -m 600 /tls/oracle-wallet/cwallet.sso /tls/oracle-wallet/ewallet.p12 /tmp/oracle-matrix-wallet/
cat >> "$ORACLE_HOME/network/admin/sqlnet.ora" <<'CFG'

WALLET_LOCATION = (SOURCE = (METHOD = FILE) (METHOD_DATA = (DIRECTORY = /tmp/oracle-matrix-wallet)))
SSL_CLIENT_AUTHENTICATION = FALSE
CFG
sed -i '/(ADDRESS = (PROTOCOL = TCP)/a\      (ADDRESS = (PROTOCOL = TCPS)(HOST=)(PORT = 2484))' "$ORACLE_HOME/network/admin/listener.ora"
cat >> "$ORACLE_HOME/network/admin/listener.ora" <<'CFG'

WALLET_LOCATION = (SOURCE = (METHOD = FILE) (METHOD_DATA = (DIRECTORY = /tmp/oracle-matrix-wallet)))
SSL_CLIENT_AUTHENTICATION = FALSE
CFG
exec /opt/oracle/container-entrypoint.sh "$@"
