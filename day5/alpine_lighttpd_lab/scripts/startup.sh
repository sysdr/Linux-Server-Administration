#!/bin/bash
# Day5: Startup/demo script. Run with full path.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$LAB_ROOT" || exit 1
LOCK="${TMPDIR:-/tmp}/day5_startup.lock"
if [ -f "$LOCK" ]; then
    old_pid=$(cat "$LOCK" 2>/dev/null)
    if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null && [ "$old_pid" != "$$" ]; then
        echo "  [SKIP] Day5 startup already running (avoid duplicate)."
        exit 0
    fi
fi
echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT
echo "  [START] Day5 Alpine Lighttpd demo from $LAB_ROOT"
echo -e "\n\e[1;35m===========================================================\e[0m"
echo -e "\e[1;35m  Day5: Alpine Lighttpd Micro-Server Demo\e[0m"
echo -e "\e[1;35m===========================================================\e[0m"
CONTAINER_NAME="alpine-lighttpd-web"
HOST_PORT="8080"
echo -e "  Container: $CONTAINER_NAME"
echo -e "  URL:       http://localhost:$HOST_PORT"
echo -e "  Time:      $(date)"
SCRIPT_COUNT=0
[ -f "$LAB_ROOT/scripts/startup.sh" ] && SCRIPT_COUNT=$((SCRIPT_COUNT+1))
[ -f "$LAB_ROOT/scripts/verify_setup.sh" ] && SCRIPT_COUNT=$((SCRIPT_COUNT+1))
[ -f "$LAB_ROOT/scripts/run_tests.sh" ] && SCRIPT_COUNT=$((SCRIPT_COUNT+1))
[ -f "$LAB_ROOT/scripts/stop.sh" ] && SCRIPT_COUNT=$((SCRIPT_COUNT+1))
CONTAINER_UP=0
docker ps -q -f name="^${CONTAINER_NAME}$" | grep -q . && CONTAINER_UP=1
CURL_OK=0
curl -sf "http://localhost:${HOST_PORT}" | grep -q "Alpine Lighttpd" && CURL_OK=1
echo -e "  \e[1;36mDashboard metrics (updated by demo):\e[0m"
echo -e "    Scripts: $SCRIPT_COUNT  Container running: $CONTAINER_UP  Web OK: $CURL_OK"
echo -e "\e[1;35m===========================================================\e[0m\n"
