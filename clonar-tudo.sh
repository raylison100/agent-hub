#!/usr/bin/env bash
# Clona os repositorios do Agent Hub nas subpastas deste diretorio, pulando os que ja existem.
set -euo pipefail
cd "$(dirname "$0")"
DONO="${AGENT_HUB_OWNER:-raylison100}"
BASE="${AGENT_HUB_GIT_BASE:-https://github.com/$DONO}"

for pasta in core daemon web agents desktop relay channels docs; do
  if [ -d "$pasta/.git" ]; then
    echo "ja existe: $pasta"
    continue
  fi
  git clone "$BASE/agent-hub-$pasta.git" "$pasta"
done
