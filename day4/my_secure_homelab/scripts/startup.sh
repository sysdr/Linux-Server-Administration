#!/bin/bash
# Day4: Startup/demo script. Run with full path.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$LAB_ROOT" || exit 1
LOCK="${TMPDIR:-/tmp}/day4_startup.lock"
if [ -f "$LOCK" ]; then
    old_pid=$(cat "$LOCK" 2>/dev/null)
    if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null && [ "$old_pid" != "$$" ]; then
        echo "  [SKIP] Day4 startup already running (avoid duplicate)."
        exit 0
    fi
fi
echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT
echo "  [START] Day4 demo from $LAB_ROOT"
echo -e "\n\e[1;35m===========================================================\e[0m"
echo -e "\e[1;35m  Day4: Secure Headless Lab - Demo\e[0m"
echo -e "\e[1;35m===========================================================\e[0m"
echo -e "  Config:  $LAB_ROOT/config"
echo -e "  Logs:    $LAB_ROOT/logs"
echo -e "  Scripts: $LAB_ROOT/scripts"
echo -e "  Time:    $(date)"
CONFIG_COUNT=0
[ -f "$LAB_ROOT/config/id_rsa_lab" ] && CONFIG_COUNT=$((CONFIG_COUNT+1))
[ -f "$LAB_ROOT/config/id_rsa_lab.pub" ] && CONFIG_COUNT=$((CONFIG_COUNT+1))
[ -f "$LAB_ROOT/config/Dockerfile.snippet" ] && CONFIG_COUNT=$((CONFIG_COUNT+1))
SCRIPT_COUNT=0
[ -f "$LAB_ROOT/scripts/startup.sh" ] && SCRIPT_COUNT=$((SCRIPT_COUNT+1))
[ -f "$LAB_ROOT/scripts/verify_setup.sh" ] && SCRIPT_COUNT=$((SCRIPT_COUNT+1))
[ -f "$LAB_ROOT/scripts/run_tests.sh" ] && SCRIPT_COUNT=$((SCRIPT_COUNT+1))
echo -e "  \e[1;36mDashboard metrics (updated by demo):\e[0m"
echo -e "    Config files: $CONFIG_COUNT  Scripts: $SCRIPT_COUNT"
echo -e "\e[1;35m===========================================================\e[0m\n"
