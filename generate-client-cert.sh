#!/bin/bash 

# create-ca.sh
# Generates a Root CA (ca.crt + ca.key)

set -euo pipefail

# Output filenames
CA_KEY="ca.key"
CA_CRT="ca.crt"

echo "[*] Generating a 4096-bit Root CA private key..."
openssl genrsa -out "$CA_KEY" 4096

echo "[*] Generating Root CA certificate (valid 10 years)..."
openssl req -x509 -new -nodes \
    -key "$CA_KEY" \
    -sha256 \
    -days 3650 \
    -out "$CA_CRT" \
    -subj "/CN=My Local CA"

echo
echo "[✓] Root CA created:"
echo "    $CA_KEY"
echo "    $CA_CRT"

echo "[*] CA Thumbprint:"
openssl x509 -in "$CA_CRT" -noout -fingerprint -sha256
