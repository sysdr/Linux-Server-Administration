#!/bin/bash
# Day5: Verify Alpine Lighttpd lab artifacts. Run with full path or from LAB_ROOT.
LAB_ROOT="${LAB_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SCRIPTS_DIR="$LAB_ROOT/scripts"
CONTAINER_NAME="alpine-lighttpd-web"
HOST_PORT="8080"
FAIL=0
check() { if [ -e "$1" ]; then echo "  OK   $1"; else echo "  FAIL $1"; FAIL=1; fi; }
echo "Verifying Day5 Alpine Lighttpd lab under $LAB_ROOT"
check "$LAB_ROOT"
check "$SCRIPTS_DIR"
check "$SCRIPTS_DIR/startup.sh"
check "$SCRIPTS_DIR/verify_setup.sh"
check "$SCRIPTS_DIR/run_tests.sh"
check "$SCRIPTS_DIR/stop.sh"
if command -v docker &>/dev/null; then
    if docker ps -q -f name="^${CONTAINER_NAME}$" | grep -q .; then
        echo "  OK   Container $CONTAINER_NAME is running"
    else
        echo "  FAIL Container $CONTAINER_NAME is not running"
        FAIL=1
    fi
fi
if command -v curl &>/dev/null; then
    if curl -sf "http://localhost:${HOST_PORT}" | grep -q "Alpine Lighttpd"; then
        echo "  OK   Web server responding at http://localhost:$HOST_PORT"
    else
        echo "  FAIL Web server not responding at http://localhost:$HOST_PORT"
        FAIL=1
    fi
fi
if [ $FAIL -eq 0 ]; then echo "  All checks passed."; exit 0; else exit 1; fi
