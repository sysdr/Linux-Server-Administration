#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_DIR="$SCRIPT_DIR/.pids"
DASHBOARD_PID="$PID_DIR/dashboard.pid"
VM_NAME="headless-lab-node"

# Stop dashboard
if [ -f "$DASHBOARD_PID" ]; then
    pid=$(cat "$DASHBOARD_PID")
    if kill -0 "$pid" 2>/dev/null; then kill "$pid" 2>/dev/null || true; echo "Stopped dashboard (PID $pid)"; fi
    rm -f "$DASHBOARD_PID"
fi
pkill -f "dashboard.py" 2>/dev/null || true

# Stop and delete VM
if multipass info "$VM_NAME" &>/dev/null; then
    multipass delete "$VM_NAME" --purge
    echo "VM $VM_NAME deleted."
fi
rm -f "$SCRIPT_DIR/status.json"
echo "Stop complete."
