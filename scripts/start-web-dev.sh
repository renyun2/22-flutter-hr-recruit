#!/usr/bin/env bash
# Default container CMD: backend :3009 + Flutter Web :5174 + reverse proxy :5173.
set -euo pipefail

SESSION_BACKEND=backend-dev
tmux kill-session -t "${SESSION_BACKEND}" 2>/dev/null || true
tmux new-session -d -s "${SESSION_BACKEND}" \
  "cd /app/backend && exec npm start"

cd /app/mobile
flutter pub get

SESSION_PROXY=web-proxy
tmux kill-session -t "${SESSION_PROXY}" 2>/dev/null || true
tmux new-session -d -s "${SESSION_PROXY}" \
  "exec node /app/scripts/web-proxy.js"

SESSION=flutter-dev
tmux kill-session -t "${SESSION}" 2>/dev/null || true
tmux new-session -d -s "${SESSION}" \
  "cd /app/mobile && exec flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5174 --host-vmservice-port 8181"

printf '%s\n' \
  '[dev] Backend API in tmux session: backend-dev  (container :3009, host map 8800:3009)' \
  '[dev] Web reverse proxy in tmux session: web-proxy  (container :5173, host map 8811:5173)' \
  '[dev] Proxy routes:  /  + assets + ws  -> flutter :5174 (127.0.0.1 only)' \
  '[dev] Proxy routes:  /api + /health   -> backend :3009' \
  '[dev] Browser entry (env-1): http://localhost:8811/  (App + API same origin)' \
  '[dev] Do NOT open Flutter :5174 directly; use :5173 proxy only' \
  '[dev] Demo login: hr1 / 123456 (roles: hr, manager1, candidate1, interviewer1)' \
  '[dev] Flutter internal in tmux session: flutter-dev  (:5174, not exposed to host)' \
  '[dev] Attach backend:  tmux attach -t backend-dev' \
  '[dev] Attach proxy:    tmux attach -t web-proxy' \
  '[dev] Attach flutter:  tmux attach -t flutter-dev  (r=reload, R=restart, q=quit)' \
  '[dev] Detach tmux without stopping:  Ctrl+b then d' \
  '[dev] Foreground flutter:  /app/scripts/dev-web.sh' \
  '[dev] Interactive flutter: /app/scripts/flutter-run-web.sh  (API -> :3009, open printed URL)' \
  '[dev] Foreground backend:  /app/scripts/dev-backend.sh'
