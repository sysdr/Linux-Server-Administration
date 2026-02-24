#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
BASE_URL="${DASHBOARD_URL:-http://127.0.0.1:5000}"
FAIL=0

echo "=== 1. File structure ==="
for f in system_health.py dashboard.py requirements.txt start.sh stop.sh monitor_agent.sh templates/index.html; do
    if [ -f "$f" ] || [ -e "$f" ]; then echo "  OK $f"; else echo "  MISSING $f"; FAIL=1; fi
done

echo "=== 2. Dashboard API (expect dashboard running) ==="
if ! curl -sf "$BASE_URL/api/metrics" -o /tmp/metrics.json 2>/dev/null; then
    echo "  Dashboard not reachable at $BASE_URL. Run: $SCRIPT_DIR/start.sh"
    FAIL=1
else
    echo "  OK API reachable"
    for key in cpu_percent mem_percent mem_total_gb disk_percent disk_total_gb uptime hostname timestamp; do
        if grep -q "\"$key\"" /tmp/metrics.json 2>/dev/null; then echo "  OK key $key"; else echo "  MISSING key $key"; FAIL=1; fi
    done
    mem_p=$(grep -o '"mem_percent":[^,}]*' /tmp/metrics.json | cut -d: -f2)
    disk_p=$(grep -o '"disk_percent":[^,}]*' /tmp/metrics.json | cut -d: -f2)
    echo "  mem_percent=$mem_p disk_percent=$disk_p (should be non-zero when running)"
    if [ -n "$mem_p" ] && [ -n "$disk_p" ]; then echo "  OK metrics present"; else echo "  WARN: metrics may be zero if dashboard just started"; fi
fi

echo "=== 3. Duplicate processes ==="
count=$(pgrep -f "dashboard.py" 2>/dev/null | wc -l)
if [ "$count" -gt 1 ]; then echo "  WARNING: $count dashboard processes (run stop.sh then start.sh)"; else echo "  OK dashboard processes: $count"; fi

if [ "$FAIL" -eq 0 ]; then echo "=== All checks passed ==="; exit 0; else echo "=== Some checks failed ==="; exit 1; fi
