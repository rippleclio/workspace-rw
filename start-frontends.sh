#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "============================================"
echo "  Starting all frontend dev servers"
echo "============================================"
echo

echo "[1/4] wabifair-storefront-web  (port 3000)"
(cd "$SCRIPT_DIR/wabifair-storefront-web" && npm run dev) &

echo "[2/4] wabifair-admin-console   (port 3001)"
(cd "$SCRIPT_DIR/wabifair-admin-console" && npm run dev) &

echo "[3/4] rippleclio-web           (port 5173)"
(cd "$SCRIPT_DIR/rippleclio-web" && npm run dev) &

echo "[4/4] rippleclio-admin-console (port 5174)"
(cd "$SCRIPT_DIR/rippleclio-admin-console" && npm run dev) &

echo
echo "All dev servers started:"
echo "  wabifair-storefront-web   http://localhost:3000"
echo "  wabifair-admin-console    http://localhost:3001"
echo "  rippleclio-web            http://localhost:5173"
echo "  rippleclio-admin-console  http://localhost:5174"
echo
echo "Use stop-frontends.sh to shut them all down."
echo "Press Ctrl+C to stop all servers."

wait
