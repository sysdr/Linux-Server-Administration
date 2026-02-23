#!/bin/bash
set -euo pipefail
# cleanup.sh: Stop project dashboard, stop all Docker containers, remove unused Docker resources.
# Run from project directory: ./cleanup.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "--- Stopping project dashboard (if running) ---"
if [ -f ".pids/dashboard.pid" ]; then
    pid=$(cat .pids/dashboard.pid 2>/dev/null)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true
        echo "Stopped dashboard (PID $pid)"
    fi
    rm -f .pids/dashboard.pid
fi
pkill -f "dashboard.py" 2>/dev/null || true
echo "Dashboard stopped."

echo "--- Stopping all Docker containers ---"
if command -v docker &>/dev/null; then
    running=$(docker ps -aq 2>/dev/null | wc -l)
    if [ "$running" -gt 0 ]; then
        docker stop $(docker ps -aq) 2>/dev/null || true
        echo "Stopped all containers."
    else
        echo "No running containers."
    fi

    echo "--- Removing stopped containers ---"
    docker container prune -f

    echo "--- Removing unused images ---"
    docker image prune -f

    echo "--- Removing unused volumes ---"
    docker volume prune -f 2>/dev/null || true

    echo "--- Removing unused networks ---"
    docker network prune -f 2>/dev/null || true

    echo "--- Docker cleanup done ---"
else
    echo "Docker not found; skipping Docker cleanup."
fi

echo "--- Cleanup finished ---"
