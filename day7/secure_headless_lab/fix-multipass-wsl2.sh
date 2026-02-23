#!/bin/bash
# Fix multipass on WSL2/Linux when client fails with:
#   failed to open file '.../multipass_root_cert.pem': No such file or directory
# Run once after installing multipass (e.g. sudo snap install multipass --classic).

set -euo pipefail

CERT_DIR="/var/snap/multipass/common/data/multipassd/certificates"
ROOT_CERT="/var/snap/multipass/common/data/multipassd/multipass_root_cert.pem"

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run with sudo (to fix cert directory permissions)."
  echo "Usage: sudo $0"
  exit 1
fi

echo "[INFO] Ensuring multipass certificate directory and root cert are accessible..."
mkdir -p "$CERT_DIR"
chmod 755 "$CERT_DIR"
chown -R root:root /var/snap/multipass/common/data/multipassd

# Client may look in certificates/ subdir; copy root cert there if it exists in parent
if [ -f "$ROOT_CERT" ] && [ ! -f "$CERT_DIR/multipass_root_cert.pem" ]; then
  cp "$ROOT_CERT" "$CERT_DIR/multipass_root_cert.pem"
  chmod 644 "$CERT_DIR/multipass_root_cert.pem"
  echo "[OK] Copied multipass_root_cert.pem into certificates/"
fi

echo "[OK] multipass certificate fix applied. Try: multipass list"
