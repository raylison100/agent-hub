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
if command -v docker >/dev/null 2>&1 && [ -z "${OLLAMA_BASE_URL:-}" ]; then
  COMPOSE_FILES="-f $ROOT/docker-compose.yml"
  if command -v nvidia-ctk >/dev/null 2>&1 && docker info 2>/dev/null | grep -qi nvidia; then
    COMPOSE_FILES="$COMPOSE_FILES -f $ROOT/docker-compose.gpu.yml"
    echo "ollama: GPU NVIDIA habilitada"
  fi
  (cd "$ROOT" && docker compose $COMPOSE_FILES up -d ollama >/dev/null 2>&1 && echo "ollama: container agent-hub-ollama") || echo "ollama: docker compose falhou, seguindo sem ele"
fi
if [ -z "${OLLAMA_BASE_URL:-}" ]; then
  if curl -s -m 2 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
    export OLLAMA_BASE_URL="http://127.0.0.1:11434/v1"
  else
    export OLLAMA_BASE_URL="http://$WIN_HOST:11434/v1"
  fi
fi
echo "OLLAMA_BASE_URL=$OLLAMA_BASE_URL"

HOME_DIR="${AGENT_HUB_HOME:-$HOME/.agent-hub}"
mkdir -p "$HOME_DIR"
if [ ! -f "$HOME_DIR/.env" ]; then
  (cd "$ROOT/daemon" && node dist/cli.js init >/dev/null 2>&1 || true)
fi
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

PORT="$(grep -E '^port' "$HOME_DIR/config.toml" | head -1 | tr -dc '0-9')"
PORT="${PORT:-47311}"
echo
echo "interface em http://127.0.0.1:$PORT (o daemon serve a web e entrega a credencial sozinho nesta maquina)"
echo "Ctrl+C encerra."
echo
exec node "$ROOT/daemon/dist/cli.js" start
