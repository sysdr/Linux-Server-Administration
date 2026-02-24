#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/logs/agent.log"
SLEEP_INTERVAL=5
trap 'echo "$(date): Agent stopped." >> "$LOG_FILE"; exit 0' SIGTERM
mkdir -p "$(dirname "$LOG_FILE")"
echo "Agent started at $(date)" >> "$LOG_FILE"
while true; do
    echo "$(date): Heartbeat - Agent is alive." >> "$LOG_FILE"
    sleep "$SLEEP_INTERVAL"
done
