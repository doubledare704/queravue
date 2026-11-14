#!/usr/bin/env bash
# Generates the dev CA, server and client certificates and the bastion SSH key
# into dev/tls/out (gitignored). Dev-only: keys are world-readable so the
# database containers can read them. Idempotent: existing files are kept, so
# CI and laptops get a stable set; pass --force to regenerate.
#   dev/tls/gen.sh [--force]
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
out="$here/out"
days=3650
servers=(postgres-tls mysql-tls mongo-tls clickhouse-tls)

[[ "${1:-}" == "--force" ]] && rm -rf "$out"
mkdir -p "$out/ssh"

if [[ ! -f "$out/ca.pem" ]]; then
  openssl ecparam -name prime256v1 -genkey -noout -out "$out/ca.key"
  openssl req -x509 -new -key "$out/ca.key" -sha256 -days "$days" \
    -subj "/CN=Queravue dev CA" -out "$out/ca.pem"
fi

issue() {
  local name="$1" usage="$2" san="$3"
  [[ -f "$out/$name.pem" ]] && return
  openssl ecparam -name prime256v1 -genkey -noout | openssl pkcs8 -topk8 -nocrypt -out "$out/$name.key"
  openssl req -new -key "$out/$name.key" -subj "/CN=$name" -out "$out/$name.csr"
  printf 'subjectAltName=%s\nextendedKeyUsage=%s\nbasicConstraints=CA:FALSE\n' "$san" "$usage" >"$out/$name.ext"
  openssl x509 -req -in "$out/$name.csr" -CA "$out/ca.pem" -CAkey "$out/ca.key" -CAcreateserial \
    -sha256 -days "$days" -extfile "$out/$name.ext" -out "$out/$name.crt"
  cat "$out/$name.crt" "$out/$name.key" >"$out/$name.pem"
  rm -f "$out/$name.csr" "$out/$name.ext"
}

for s in "${servers[@]}"; do
  issue "$s" serverAuth "DNS:$s,DNS:localhost,IP:127.0.0.1"
done
issue client clientAuth "DNS:queravue-client"

if [[ ! -f "$out/ssh/id_ed25519" ]]; then
  ssh-keygen -q -t ed25519 -N "" -C queravue-dev -f "$out/ssh/id_ed25519"
  ssh-keygen -q -t ed25519 -N "dev-passphrase" -C queravue-dev-encrypted -f "$out/ssh/id_ed25519_encrypted"
  cat "$out/ssh/id_ed25519.pub" "$out/ssh/id_ed25519_encrypted.pub" >"$out/ssh/authorized_keys"
fi

chmod 644 "$out"/*.key "$out"/*.pem "$out"/*.crt "$out"/ssh/authorized_keys
chmod 600 "$out"/ssh/id_ed25519 "$out"/ssh/id_ed25519_encrypted
echo "dev TLS and SSH material in $out"
