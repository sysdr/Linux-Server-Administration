#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_DIR="$SCRIPT_DIR/.pids"
DASHBOARD_PID="$PID_DIR/dashboard.pid"
AGENT_PID="$PID_DIR/agent.pid"
stopped=0

if [ -f "$AGENT_PID" ]; then
    pid=$(cat "$AGENT_PID")
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true
        echo "Stopped agent (PID $pid)"
        stopped=1
    fi
    rm -f "$AGENT_PID"
fi
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
pkill -f "monitor_agent.sh" 2>/dev/null || true
if [ "$stopped" -eq 0 ]; then
    echo "No project processes found to stop."
fi
