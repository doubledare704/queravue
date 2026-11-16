#!/usr/bin/env bash
set -euo pipefail
out="$(cd "$(dirname "$0")/../out" && pwd)"
[[ ! -s "$out/oracle-wallet/cwallet.sso" ]] || exit 0
version=23.26.3.0.0
checksum=3e180d09700e56f167052c160b3a16ce5a953455187cc60986a853109fff2356
tool="$(mktemp)"
trap 'rm -f "$tool"' EXIT
curl -fsSL "https://repo.maven.apache.org/maven2/com/oracle/database/security/oraclepki/$version/oraclepki-$version.jar" -o "$tool"
printf '%s  %s\n' "$checksum" "$tool" | shasum -a 256 -c -
chmod 644 "$tool"
mkdir -p "$out/oracle-wallet"
docker run --rm --network none --user "$(id -u):$(id -g)" \
  -v "$tool:/wallet-tool.jar:ro" -v "$out:/tls:ro" -v "$out/oracle-wallet:/wallet" \
  eclipse-temurin:21-jdk@sha256:0a3f329821dcadf54b2a3033a15e2e9f007069a9db43d7f51897e6b80e726b07 \
  bash -ec '
    tool=(java -cp /wallet-tool.jar oracle.security.pki.textui.OraclePKITextUI wallet)
    "${tool[@]}" create -wallet /wallet -pwd MatrixWallet1 -auto_login
    "${tool[@]}" import_pkcs12 -wallet /wallet -pwd MatrixWallet1 \
      -pkcs12file /tls/oracle-wallet.p12 -pkcs12pwd MatrixWallet1
  '
chmod 644 "$out/oracle-wallet/"{cwallet.sso,ewallet.p12}
