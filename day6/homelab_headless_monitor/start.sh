#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
PID_DIR="$SCRIPT_DIR/.pids"
mkdir -p "$PID_DIR"
DASHBOARD_PID="$PID_DIR/dashboard.pid"
PORT="${DASHBOARD_PORT:-5000}"

if [ -f "$DASHBOARD_PID" ] && kill -0 "$(cat "$DASHBOARD_PID")" 2>/dev/null; then
    echo "Dashboard already running (PID $(cat "$DASHBOARD_PID")). Use stop.sh first."
    exit 1
fi

if ! command -v python3 &>/dev/null; then
    echo "python3 not found. Install Python 3 and run again."
    exit 1
fi
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
. venv/bin/activate
pip install -q -r requirements.txt
export PORT="$PORT"
echo "Starting dashboard on http://0.0.0.0:$PORT"
python3 dashboard.py &
echo $! > "$DASHBOARD_PID"
echo "Dashboard started (PID $(cat "$DASHBOARD_PID")). Open http://localhost:$PORT"
