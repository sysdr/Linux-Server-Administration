#!/bin/bash
# Homelab 2026 - Cleanup: stop containers, prune Docker, remove build/cache artifacts.
set -e
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT" || exit 1

echo "=== Cleanup: Stopping containers and pruning Docker ==="

# Stop all running containers
if command -v docker &>/dev/null; then
    RUNNING=$(docker ps -q 2>/dev/null || true)
    if [ -n "$RUNNING" ]; then
        echo "  Stopping running containers..."
        docker stop $RUNNING 2>/dev/null || true
    fi
    echo "  Pruning unused Docker resources..."
    docker system prune -af --volumes 2>/dev/null || true
    docker volume prune -f 2>/dev/null || true
    docker container prune -f 2>/dev/null || true
    docker image prune -af 2>/dev/null || true
    echo "  Docker cleanup done."
else
    echo "  Docker not found or not running; skipping."
fi

echo ""
echo "=== Cleanup: Removing project artifacts (node_modules, venv, caches, etc.) ==="

# Remove common build/cache artifacts from project tree
# Directories
for dir in node_modules venv .pytest_cache vendor __pycache__; do
    find "$PROJECT_ROOT" -type d -name "$dir" -not -path "$PROJECT_ROOT/.git/*" -print0 2>/dev/null | while IFS= read -r -d '' path; do
        [ -d "$path" ] || continue
        echo "  Removing dir: $path"
        rm -rf "$path"
    done
done
# Files
find "$PROJECT_ROOT" -type f \( -name "*.pyc" -o -name "*.rr" \) -not -path "$PROJECT_ROOT/.git/*" -print0 2>/dev/null | while IFS= read -r -d '' path; do
    echo "  Removing file: $path"
    rm -f "$path"
done
# Istio (dirs or files with istio in name)
find "$PROJECT_ROOT" -maxdepth 4 \( -type d -o -type f \) -iname "*istio*" -not -path "$PROJECT_ROOT/.git/*" -print0 2>/dev/null | while IFS= read -r -d '' path; do
    [ -e "$path" ] || continue
    echo "  Removing: $path"
    rm -rf "$path"
done

echo "  Project artifact cleanup done."
echo ""
echo "=== Cleanup complete ==="
