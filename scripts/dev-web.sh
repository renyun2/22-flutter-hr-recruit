#!/usr/bin/env bash
# Foreground Flutter Web dev server — use for interactive hot reload (r / R / q).
# App pages must be opened via web-proxy (:5173), not Flutter internal :5174.
set -euo pipefail
cd /app/mobile

if ! curl -sf --max-time 1 "http://127.0.0.1:${WEB_PROXY_PORT:-5173}/" >/dev/null 2>&1; then
  node /app/scripts/web-proxy.js &
  PROXY_PID=$!
  trap 'kill "${PROXY_PID}" 2>/dev/null || true' EXIT
  sleep 0.5
fi

flutter pub get

exec flutter run -d web-server \
  --web-hostname 127.0.0.1 \
  --web-port 5174 \
  --host-vmservice-port 8181
