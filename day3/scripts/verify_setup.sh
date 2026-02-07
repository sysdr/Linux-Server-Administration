#!/bin/bash
# Day3: Verify all setup artifacts. Run with full path or from DAY3_ROOT.
DAY3_ROOT="${DAY3_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CONFIG_DIR="$DAY3_ROOT/config"
LOG_DIR="$DAY3_ROOT/logs"
SCRIPTS_DIR="$DAY3_ROOT/scripts"
SSH_KEY_DIR="$CONFIG_DIR/ssh_keys"
FAIL=0
check() { if [ -e "$1" ]; then echo "  OK   $1"; else echo "  FAIL $1"; FAIL=1; fi; }
echo "Verifying Day3 setup artifacts under $DAY3_ROOT"
check "$DAY3_ROOT"
check "$CONFIG_DIR"
check "$LOG_DIR"
check "$SCRIPTS_DIR"
check "$SSH_KEY_DIR"
check "$SCRIPTS_DIR/startup.sh"
check "$SCRIPTS_DIR/verify_setup.sh"
check "$SCRIPTS_DIR/run_tests.sh"
if [ $FAIL -eq 0 ]; then echo "  All checks passed."; exit 0; else exit 1; fi
