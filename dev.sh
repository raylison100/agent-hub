#!/usr/bin/env bash
# Sobe daemon e interface web em localhost para teste. Chaves de API vem do
# ambiente de quem roda o script: exporte ANTHROPIC_API_KEY, DEEPSEEK_API_KEY
# e OPENAI_API_KEY antes.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && nvm use 24 >/dev/null

if [ -z "${WIN_HOST:-}" ] && grep -qi microsoft /proc/version 2>/dev/null; then
  export WIN_HOST="$(ip route | awk '/default/ {print $3; exit}')"
  echo "WIN_HOST=$WIN_HOST (gateway do WSL para o Windows; Ollama precisa escutar em 0.0.0.0)"
fi
export WIN_HOST="${WIN_HOST:-127.0.0.1}"

HOME_DIR="${AGENT_HUB_HOME:-$HOME/.agent-hub}"
mkdir -p "$HOME_DIR"
if [ ! -f "$HOME_DIR/config.toml" ]; then
  cat > "$HOME_DIR/config.toml" <<EOF
agents_dir = "$ROOT/agents"
host = "127.0.0.1"
port = 47311
workspaces = ["$ROOT", "$HOME/Projects"]
approval_timeout_ms = 600000
device_name = "$(hostname)"
EOF
  echo "config criado em $HOME_DIR/config.toml"
fi

(cd "$ROOT/core" && pnpm build >/dev/null)
(cd "$ROOT/daemon" && pnpm build >/dev/null)
(cd "$ROOT/web" && pnpm exec vite build >/dev/null)

node "$ROOT/daemon/dist/cli.js" start &
DAEMON=$!
trap 'kill $DAEMON 2>/dev/null' EXIT
sleep 2
node "$ROOT/daemon/dist/cli.js" pair --web http://localhost:4173 --no-qr
echo
echo "interface em http://localhost:4173 (Ctrl+C encerra os dois)"
(cd "$ROOT/web" && pnpm exec vite preview --host 127.0.0.1 --port 4173 --strictPort)
