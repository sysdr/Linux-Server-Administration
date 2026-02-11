#!/bin/bash
# Day4: Run verification tests. Use full path or run from LAB_ROOT.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY="$SCRIPT_DIR/verify_setup.sh"
if [ ! -f "$VERIFY" ]; then
    echo "ERROR: Run setup.sh first. $VERIFY not found."
    exit 1
fi
exec "$VERIFY"
