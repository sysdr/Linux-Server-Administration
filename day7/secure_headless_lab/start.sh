#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VM_NAME="headless-lab-node"
VM_MEMORY="2G"
VM_CPUS="2"
VM_DISK="10G"
USER_DATA_FILE="user-data.yaml"
STATUS_FILE="status.json"
SSH_PUB_KEY_PATH="${HOME}/.ssh/id_rsa.pub"
PID_DIR="$SCRIPT_DIR/.pids"
DASHBOARD_PID="$PID_DIR/dashboard.pid"
PORT="${DASHBOARD_PORT:-5000}"

# Check dashboard not already running
mkdir -p "$PID_DIR"
if [ -f "$DASHBOARD_PID" ] && kill -0 "$(cat "$DASHBOARD_PID")" 2>/dev/null; then
    echo "Dashboard already running (PID $(cat "$DASHBOARD_PID")). Use stop.sh first."
    exit 1
fi

if [ ! -f "$USER_DATA_FILE" ]; then
    echo "Missing $USER_DATA_FILE in $SCRIPT_DIR. Run setup.sh first."
    exit 1
fi

# Require multipass: project is based on real VM output only
if ! command -v multipass &>/dev/null; then
    echo "[ERROR] multipass is required. This project uses real VM output only (no demo/synthetic status)."
    echo "Install: sudo snap install multipass --classic"
    echo "Then run this script again."
    exit 1
fi
if ! command -v jq &>/dev/null; then
    echo "[ERROR] jq is required. Install: sudo apt-get install -y jq"
    exit 1
fi

# Optional: inject SSH key into user-data if present
if [ -f "$SSH_PUB_KEY_PATH" ]; then
    sed -i.bak "s|REPLACE_WITH_YOUR_SSH_PUBLIC_KEY|$(cat "$SSH_PUB_KEY_PATH")|" "$USER_DATA_FILE" 2>/dev/null || true
fi

echo "[INFO] Launching VM $VM_NAME with cloud-init..."
if multipass info "$VM_NAME" &>/dev/null; then
    echo "[WARN] VM $VM_NAME already exists. Use stop.sh first to remove it."
    exit 1
fi

if ! multipass launch --name "$VM_NAME" \
    --memory "$VM_MEMORY" \
    --cpus "$VM_CPUS" \
    --disk "$VM_DISK" \
    --cloud-init "$USER_DATA_FILE"; then
    echo "[ERROR] multipass launch failed. On WSL2, see: https://multipass.run/docs/troubleshooting-networking-in-wsl"
    exit 1
fi

echo "[INFO] Waiting for VM IP and cloud-init..."
WAIT_TIMEOUT=600
WAIT_ELAPSED=0
VM_IP=""
while [ $WAIT_ELAPSED -lt $WAIT_TIMEOUT ]; do
  VM_IP="$(multipass info "$VM_NAME" --format json 2>/dev/null | jq -r --arg n "$VM_NAME" '.info[$n].ipv4[0] // empty')"
  [ -n "$VM_IP" ] && break
  sleep 5
  WAIT_ELAPSED=$((WAIT_ELAPSED + 5))
done
[ -z "$VM_IP" ] && { echo "VM did not get an IP within ${WAIT_TIMEOUT}s."; exit 1; }
# Allow cloud-init to finish (nginx, ufw, sysadmin)
echo "[INFO] Allowing cloud-init to complete..."
sleep 30
for _ in 1 2 3 4 5 6 7 8 9 10; do
  if multipass exec "$VM_NAME" -- cloud-init status 2>/dev/null | grep -q "status: done"; then
    break
  fi
  sleep 10
done
echo "[INFO] VM ready at $VM_IP"

# Verifications (real output from VM)
NGINX_OK="false"
curl -s -m 5 "http://$VM_IP" | grep -q "Welcome to nginx" && NGINX_OK="true" || true

UFW_OK="false"
UFW_OUT="$(multipass exec "$VM_NAME" -- sudo ufw status 2>/dev/null || true)"
echo "$UFW_OUT" | grep -q "Status: active" && echo "$UFW_OUT" | grep -q "22/tcp" && UFW_OK="true" || true

SSH_OK="false"
multipass exec "$VM_NAME" -- id sysadmin &>/dev/null && SSH_OK="true" || true

# Write status for dashboard from real VM verification (no demo/synthetic values)
cat > "$STATUS_FILE" <<STATUSJSON
{
  "vm_name": "$VM_NAME",
  "vm_ip": "$VM_IP",
  "nginx_ok": $NGINX_OK,
  "ufw_ok": $UFW_OK,
  "ssh_ok": $SSH_OK,
  "timestamp": "$(date -Iseconds)",
  "ssh_user": "sysadmin",
  "nginx_url": "http://$VM_IP"
}
STATUSJSON

echo "[SUCCESS] VM ready (real). IP: $VM_IP Nginx: $NGINX_OK UFW: $UFW_OK SSH user: $SSH_OK"

# Start dashboard so real VM metrics are visible
if command -v python3 &>/dev/null; then
    [ ! -d "$SCRIPT_DIR/venv" ] && python3 -m venv "$SCRIPT_DIR/venv"
    . "$SCRIPT_DIR/venv/bin/activate"
    pip install -q -r "$SCRIPT_DIR/requirements.txt" 2>/dev/null || true
    export PORT="$PORT"
    python3 "$SCRIPT_DIR/dashboard.py" &
    echo $! > "$DASHBOARD_PID"
    echo "Dashboard started at http://127.0.0.1:$PORT (metrics from status.json)"
else
    echo "python3 not found; dashboard not started. Status written to $STATUS_FILE"
fi
