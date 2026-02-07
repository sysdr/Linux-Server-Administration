#!/bin/bash
# Homelab 2026 - Startup script. Run with full path: $SCRIPTS_DIR/startup.sh
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT" || exit 1
# Avoid duplicate: only one lab_manager demo at a time
if pgrep -f "lab_manager.sh" | grep -v "$$" >/dev/null 2>&1; then
    echo "  [SKIP] lab_manager already running (avoid duplicate)."
    exit 0
fi
echo "  [START] Running lab manager demo from $PROJECT_ROOT"
exec "$SCRIPT_DIR/lab_manager.sh"
