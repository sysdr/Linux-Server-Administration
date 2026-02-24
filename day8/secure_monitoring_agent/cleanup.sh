#!/bin/bash
set -euo pipefail
# Stop project processes and remove unused Docker resources (containers, images, etc.).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
PID_DIR="$SCRIPT_DIR/.pids"
DASHBOARD_PID="$PID_DIR/dashboard.pid"
AGENT_PID="$PID_DIR/agent.pid"

echo "--- Stopping project services (dashboard and agent) ---"
for pidfile in "$DASHBOARD_PID" "$AGENT_PID"; do
    if [ -f "$pidfile" ]; then
        pid=$(cat "$pidfile" 2>/dev/null)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            echo "Stopped process (PID $pid)"
        fi
        rm -f "$pidfile"
    fi
done
pkill -f "dashboard.py" 2>/dev/null || true
pkill -f "monitor_agent.sh" 2>/dev/null || true
echo "--- Project services stopped ---"

echo "--- Stopping all Docker containers ---"
if command -v docker &>/dev/null; then
    if [ "$(docker ps -aq 2>/dev/null | wc -l)" -gt 0 ]; then
        docker stop $(docker ps -aq) 2>/dev/null || true
        echo "Stopped all containers."
    fi
    docker container prune -f
    docker image prune -f
    docker volume prune -f 2>/dev/null || true
    docker network prune -f 2>/dev/null || true
    echo "--- Docker cleanup done (containers, images, volumes, networks pruned) ---"
else
    echo "Docker not found; skipping Docker cleanup."
fi

echo "--- Cleanup finished ---"
