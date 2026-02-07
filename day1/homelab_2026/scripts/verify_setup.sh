#!/bin/bash
# Verify all setup artifacts exist. Run with full path or from PROJECT_ROOT.
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
LOG_DIR="$PROJECT_ROOT/logs"
CONFIG_DIR="$PROJECT_ROOT/config"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"
DOCS_DIR="$PROJECT_ROOT/docs"
TEMP_DIR="$PROJECT_ROOT/tmp"
FAIL=0
check() { if [ -e "$1" ]; then echo "  OK   $1"; else echo "  FAIL $1"; FAIL=1; fi; }
echo "Verifying setup artifacts under $PROJECT_ROOT"
check "$PROJECT_ROOT"
check "$LOG_DIR"
check "$CONFIG_DIR"
check "$SCRIPTS_DIR"
check "$DOCS_DIR"
check "$TEMP_DIR"
check "$SCRIPTS_DIR/lab_manager.sh"
check "$SCRIPTS_DIR/startup.sh"
check "$SCRIPTS_DIR/verify_setup.sh"
check "$SCRIPTS_DIR/run_tests.sh"
if [ $FAIL -eq 0 ]; then echo "  All checks passed."; exit 0; else exit 1; fi
