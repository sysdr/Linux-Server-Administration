#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_DIR="$SCRIPT_DIR/.pids"
DASHBOARD_PID="$PID_DIR/dashboard.pid"
stopped=0
if [ -f "$DASHBOARD_PID" ]; then
    pid=$(cat "$DASHBOARD_PID")
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true
        echo "Stopped dashboard (PID $pid)"
        stopped=1
    fi
    rm -f "$DASHBOARD_PID"
fi
pkill -f "dashboard.py" 2>/dev/null || true
if [ "$stopped" -eq 0 ]; then
    echo "No dashboard process found to stop."
fi
