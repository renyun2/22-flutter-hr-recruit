#!/usr/bin/env bash
# Container: interactive flutter run with backend API on :3009 (no browser proxy needed).
set -euo pipefail
cd /app/mobile
flutter pub get
exec flutter run -d web-server \
  --web-hostname 127.0.0.1 \
  --web-port 5174 \
  --host-vmservice-port 8181 \
  --dart-define=API_BASE=http://127.0.0.1:3009
