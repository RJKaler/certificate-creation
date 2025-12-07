#!/bin/bash

# install-local-ca.sh
# Installs your internal CA so Chrome/Chromium trust all your LAN certificates

set -euo pipefail

CA_FILE="${1:-ca.crt}"

if [[ ! -f "$CA_FILE" ]]; then
    echo "[!] CA file not found: $CA_FILE"
    echo "Usage: $0 /path/to/ca.crt"
    exit 1
fi

echo "[*] Installing libnss3-tools..."
sudo apt update -y
sudo apt install -y libnss3-tools

echo "[*] Ensuring NSS database exists..."
mkdir -p "$HOME/.pki/nssdb"

echo "[*] Importing CA into Chrome trust store..."
certutil -d sql:"$HOME/.pki/nssdb" -A -t "C,," -n "My Local CA" -i "$CA_FILE"

echo "[*] Verifying..."
certutil -L -d sql:"$HOME/.pki/nssdb" | grep "My Local CA" && \
    echo "[✓] CA successfully installed and trusted!" || \
    echo "[!] CA NOT found in trust store."

echo "[*] Restarting Chrome processes..."
pkill chrome || echo 'error' 

echo "[✓] Done. Chrome will now trust all certificates issued by your CA."
