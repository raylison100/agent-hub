#!/usr/bin/env bash
# Gera as notas de uma Release: como instalar ou atualizar e os commits de cada repositorio desde a versao anterior.
set -euo pipefail
TAG="$1"
VERSAO="${TAG#v}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
URL="https://github.com/raylison100/agent-hub/releases/download/$TAG/agent-hub-$VERSAO.tgz"

cat <<MD
## Instalar

\`\`\`bash
npm install -g $URL
agent-hub instalar
\`\`\`

Requisitos: Linux ou WSL, Node 22 ou superior, \`build-essential\` e \`python3\`.

## Atualizar

\`\`\`bash
agent-hub atualizar $URL
\`\`\`

## Aplicativos de desktop

Os aplicativos sao so a janela: o daemon precisa estar instalado pelo pacote acima.

- Windows: \`agent-hub-desktop-$VERSAO-windows-x64-setup.exe\`. O daemon roda no WSL; sem ele, o app mostra os comandos para instalar.
- Debian e Ubuntu: \`agent-hub-desktop-$VERSAO-amd64.deb\`, com \`sudo apt install ./agent-hub-desktop-$VERSAO-amd64.deb\`.
- Fedora e derivados: \`agent-hub-desktop-$VERSAO-x86_64.rpm\`.

Os instaladores nao sao assinados: o Windows pode avisar na primeira execucao.

## O que mudou
MD

for par in ".:agent-hub" "core:agent-hub-core" "daemon:agent-hub-daemon" "web:agent-hub-web" "agents:agent-hub-agents" "desktop:agent-hub-desktop" "relay:agent-hub-relay" "channels:agent-hub-channels" "docs:agent-hub-docs"; do
  pasta="${par%%:*}"; nome="${par##*:}"
  d="$ROOT/$pasta"
  [ -d "$d/.git" ] || continue
  anterior="$(git -C "$d" describe --tags --abbrev=0 --match 'v*' --exclude "$TAG" "$TAG" 2>/dev/null || true)"
  intervalo="${anterior:+$anterior..}$TAG"
  linhas="$(git -C "$d" log --no-merges --format='- %s' "$intervalo" | grep -v "^- Versao $VERSAO$" | head -40 || true)"
  [ -n "$linhas" ] || continue
  echo
  echo "### $nome"
  echo
  echo "$linhas"
done
