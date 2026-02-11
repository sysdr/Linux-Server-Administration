#!/bin/bash
# Day4: Verify all setup artifacts. Run with full path or from LAB_ROOT.
LAB_ROOT="${LAB_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CONFIG_DIR="$LAB_ROOT/config"
LOGS_DIR="$LAB_ROOT/logs"
SCRIPTS_DIR="$LAB_ROOT/scripts"
FAIL=0
check() { if [ -e "$1" ]; then echo "  OK   $1"; else echo "  FAIL $1"; FAIL=1; fi; }
echo "Verifying Day4 setup artifacts under $LAB_ROOT"
check "$LAB_ROOT"
check "$CONFIG_DIR"
check "$LOGS_DIR"
check "$SCRIPTS_DIR"
check "$CONFIG_DIR/id_rsa_lab"
check "$CONFIG_DIR/id_rsa_lab.pub"
check "$CONFIG_DIR/Dockerfile.snippet"
check "$SCRIPTS_DIR/startup.sh"
check "$SCRIPTS_DIR/verify_setup.sh"
check "$SCRIPTS_DIR/run_tests.sh"
if [ $FAIL -eq 0 ]; then echo "  All checks passed."; exit 0; else exit 1; fi
