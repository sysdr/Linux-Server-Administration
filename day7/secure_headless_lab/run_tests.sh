#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
BASE_URL="${DASHBOARD_URL:-http://127.0.0.1:5000}"
FAIL=0

echo "=== 1. File structure ==="
for f in user-data.yaml start.sh stop.sh dashboard.py requirements.txt templates/index.html; do
    if [ -f "$f" ] || [ -e "$f" ]; then echo "  OK $f"; else echo "  MISSING $f"; FAIL=1; fi
done

echo "=== 2. Dashboard API (expect dashboard running after start.sh) ==="
if ! curl -sf "$BASE_URL/api/status" -o /tmp/status.json 2>/dev/null; then
    echo "  Dashboard not reachable at $BASE_URL. Run: $SCRIPT_DIR/start.sh first."
    FAIL=1
else
    echo "  OK API reachable"
    for key in vm_ip nginx_ok ufw_ok ssh_ok timestamp; do
        if grep -q "\"$key\"" /tmp/status.json 2>/dev/null; then echo "  OK key $key"; else echo "  MISSING key $key"; FAIL=1; fi
    done
    vm_ip=$(grep -o '"vm_ip":"[^"]*"' /tmp/status.json | cut -d'"' -f4)
    echo "  vm_ip=$vm_ip (should be non-empty after start.sh demo)"
    if [ -n "$vm_ip" ]; then echo "  OK metrics updated"; else echo "  WARN vm_ip empty - run start.sh to populate"; FAIL=1; fi
fi

echo "=== 3. Duplicate processes ==="
count=$(pgrep -f "python.*dashboard\.py" 2>/dev/null | wc -l)
if [ "$count" -gt 1 ]; then echo "  WARNING: $count dashboard processes (run stop.sh then start.sh)"; else echo "  OK dashboard processes: $count"; fi

if [ "$FAIL" -eq 0 ]; then echo "=== All checks passed ==="; exit 0; else echo "=== Some checks failed ==="; exit 1; fi
