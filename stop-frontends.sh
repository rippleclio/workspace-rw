#!/usr/bin/env bash

echo "============================================"
echo "  Stopping all frontend dev servers"
echo "============================================"
echo

kill_port() {
  local port=$1
  local name=$2
  echo "Killing processes on port $port ($name)..."
  local pids
  pids=$(lsof -ti tcp:"$port" 2>/dev/null || true)
  if [ -n "$pids" ]; then
    echo "$pids" | xargs kill -9
  fi
}

kill_port 3000 "wabifair-storefront-web"
kill_port 3001 "wabifair-admin-console"
kill_port 5173 "rippleclio-web"
kill_port 5174 "rippleclio-admin-console"

echo
echo "All frontend dev servers stopped."
