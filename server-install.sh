#!/bin/bash
#
# server-install.sh
# Generates a SAN-enabled server certificate from your internal CA
# AND installs trust locally so Chrome on the server machine accepts it.

set -euo pipefail

HOSTNAME="${1:-}"
IPADDR="${2:-}"

CA_CRT="./ca.crt"
CA_KEY="./ca.key"

# ----------------------------------------------------
# 1. VALIDATION
# ----------------------------------------------------

if [[ -z "$HOSTNAME" || -z "$IPADDR" ]]; then
    echo "Usage: $0 <hostname> <ip-address>"
    exit 1
fi

if [[ ! -f "$CA_CRT" || ! -f "$CA_KEY" ]]; then
    echo "[!] Missing CA files: ca.crt and/or ca.key"
    exit 1
fi

echo "[*] Installing NSS tools for Chrome trust..."
sudo apt update -y
sudo apt install -y libnss3-tools || { echo "[!] Failed installing libnss3-tools"; exit 1; }

# ----------------------------------------------------
# 2. GENERATE SERVER CERTIFICATE
# ----------------------------------------------------

echo "[*] Generating key and CSR..."
openssl req -new -nodes -newkey rsa:4096 \
  -keyout server.key \
  -out server.csr \
  -subj "/CN=$HOSTNAME"

echo "[*] Generating SAN certificate signed by local CA..."
openssl x509 -req -in server.csr \
  -CA "$CA_CRT" -CAkey "$CA_KEY" -CAcreateserial \
  -out server.crt -days 825 -sha256 \
  -extfile <(printf "subjectAltName=DNS:%s,IP:%s,DNS:localhost,IP:127.0.0.1" \
  "$HOSTNAME" "$IPADDR")

echo "[✓] Server certificate created:"
echo "    server.crt"
echo "    server.key"

echo "[*] Certificate SANs:"
openssl x509 -in server.crt -noout -text | grep -A3 "Subject Alternative Name"

# ----------------------------------------------------
# 3. INSTALL CA INTO CHROME TRUST (SERVER SIDE)
# ----------------------------------------------------

echo "[*] Ensuring NSS database exists..."
mkdir -p "$HOME/.pki/nssdb"

echo "[*] Importing CA into Chrome trust store on this server..."
certutil -d sql:"$HOME/.pki/nssdb" \
    -A -t "C,," -n "My Local CA" -i "$CA_CRT"

echo "[*] Verifying CA installation..."
if certutil -L -d sql:"$HOME/.pki/nssdb" | grep -q "My Local CA"; then
    echo "[✓] CA successfully installed and trusted locally."
else
    echo "[!] CA NOT found in trust store. Import failed."
    exit 1
fi

echo "[*] Restarting Chrome processes (if running)..."
pkill chrome 2>/dev/null || echo "[i] Chrome was not running."

echo
echo "[✓] SERVER SETUP COMPLETE."
echo "[✓] Chrome on this machine now trusts your internal CA."
echo "[✓] You may now install server.crt and server.key into Cockpit or any other service."
