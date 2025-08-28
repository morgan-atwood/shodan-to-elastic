#!/usr/bin/env bash
set -euo pipefail

echo "[*] Loading .env..."
if [ ! -f .env ]; then
  echo "No .env file found. Please create one with SHODAN_API_KEY."
  exit 1
fi

# Export variables from .env
export $(grep -v '^#' .env | xargs)

if [ -z "${SHODAN_API_KEY:-}" ]; then
  echo "SHODAN_API_KEY not set in .env"
  exit 1
fi

echo "[*] Installing prerequisites..."
if [ -f /etc/debian_version ]; then
  sudo apt-get update -y
  sudo apt-get install -y python3 python3-requests curl jq logrotate
elif [ -f /etc/redhat-release ]; then
  sudo dnf install -y python3 python3-requests curl jq logrotate
else
  echo "Unsupported OS. Install python3 + requests manually."
  exit 1
fi

echo "[*] Creating directories..."
sudo mkdir -p /opt/shodan-forwarder /var/log/shodan

echo "[*] Copying forwarder script..."
sudo cp shodan_forwarder.py /opt/shodan-forwarder/
sudo chmod 0755 /opt/shodan-forwarder/shodan_forwarder.py
sudo chown root:root /opt/shodan-forwarder/shodan_forwarder.py

echo "[*] Writing system env file..."
sudo tee /etc/default/shodan-forwarder > /dev/null <<EOF
SHODAN_API_KEY=${SHODAN_API_KEY}
EOF
sudo chmod 600 /etc/default/shodan-forwarder

echo "[*] Installing systemd service..."
sudo cp shodan-forwarder.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now shodan-forwarder

echo "[*] Installing logrotate config..."
sudo cp shodan-forwarder.logrotate /etc/logrotate.d/shodan-forwarder

echo "[*] Done!"
echo "Check logs:   journalctl -u shodan-forwarder -f"
echo "Output file:  /var/log/shodan/stream.ndjson"
