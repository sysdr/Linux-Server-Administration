#!/bin/bash
# Day3: Startup/demo script. Run with full path: $SCRIPTS_DIR/startup.sh
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAY3_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$DAY3_ROOT" || exit 1
# Avoid duplicate: only one demo at a time (lock file)
LOCK="${TMPDIR:-/tmp}/day3_startup.lock"
if [ -f "$LOCK" ]; then
    old_pid=$(cat "$LOCK" 2>/dev/null)
    if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null && [ "$old_pid" != "$$" ]; then
        echo "  [SKIP] Day3 startup already running (avoid duplicate)."
        exit 0
    fi
fi
echo $$ > "$LOCK"
trap 'rm -f "$LOCK"' EXIT
echo "  [START] Day3 demo from $DAY3_ROOT"
echo -e "\n\e[1;35m===========================================================\e[0m"
echo -e "\e[1;35m  Day3: Secure Headless Home Lab - Demo\e[0m"
echo -e "\e[1;35m===========================================================\e[0m"
echo -e "  Config:  $DAY3_ROOT/config"
echo -e "  Logs:    $DAY3_ROOT/logs"
echo -e "  Scripts: $DAY3_ROOT/scripts"
echo -e "  Time:    $(date)"
echo -e "\e[1;35m===========================================================\e[0m\n"
