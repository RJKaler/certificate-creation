#!/bin/bash
#
# generate-server-cert.sh
# Issues a SAN-enabled server certificate from your internal CA

set -euo pipefail

HOSTNAME="${1:-}"
IPADDR="${2:-}"
CA_CRT="./ca.crt"
CA_KEY="./ca.key"

if [[ -z "$HOSTNAME" || -z "$IPADDR" ]]; then
    echo "Usage: $0 <hostname> <ip-address>"
    exit 1
fi

if [[ ! -f "$CA_CRT" || ! -f "$CA_KEY" ]]; then
    echo "[!] Missing CA files: ca.crt and/or ca.key"
    exit 1
fi

echo "[*] Generating key and CSR..."
openssl req -new -nodes -newkey rsa:4096 \
  -keyout server.key \
  -out server.csr \
  -subj "/CN=$HOSTNAME"

echo "[*] Generating SAN cert signed by local CA..."
openssl x509 -req -in server.csr \
  -CA "$CA_CRT" -CAkey "$CA_KEY" -CAcreateserial \
  -out server.crt -days 825 -sha256 \
  -extfile <(printf "subjectAltName=DNS:%s,IP:%s,DNS:localhost,IP:127.0.0.1" "$HOSTNAME" "$IPADDR")

echo "[✓] Server certificate created:"
echo "    server.crt"
echo "    server.key"

echo "[*] Certificate SANs:"
openssl x509 -in server.crt -noout -text | grep -A2 "Subject Alternative Name"

