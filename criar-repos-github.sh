#!/usr/bin/env bash
# Cria os nove repositorios PRIVADOS do Agent Hub na conta pessoal do GitHub.
# O token sai do .env do proprio servidor MCP; nada precisa ser colado aqui.
set -euo pipefail
ENV_MCP="$HOME/Projects/MCP/github-pessoal/.env"
[ -f "$ENV_MCP" ] || { echo "nao achei $ENV_MCP" >&2; exit 1; }
TOKEN="$(grep -E '^GITHUB_TOKEN=' "$ENV_MCP" | cut -d= -f2- | tr -d '"'"'"' \r')"
[ -n "$TOKEN" ] || { echo "GITHUB_TOKEN vazio no .env" >&2; exit 1; }

criar() {
  local nome="$1" descricao="$2"
  local codigo
  codigo=$(curl -s -o /tmp/criar-repo.json -w '%{http_code}' \
    -X POST https://api.github.com/user/repos \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Accept: application/vnd.github+json' \
    -d "{\"name\":\"$nome\",\"description\":\"$descricao\",\"private\":true,\"has_issues\":true,\"has_wiki\":false,\"auto_init\":false}")
  case "$codigo" in
    201) echo "criado   $nome" ;;
    422) echo "ja existe $nome" ;;
    *) echo "falhou   $nome (http $codigo): $(head -c 200 /tmp/criar-repo.json)" ;;
  esac
}

criar agent-hub          "Harness pessoal multi-provedor que escolhe o modelo por mensagem pelo menor custo. Raiz: compose, dev.sh e Makefile"
criar agent-hub-core     "Nucleo do Agent Hub: adaptadores de provedor, laco do agente, ferramentas, roteamento por custo x capacidade, contexto e custo"
criar agent-hub-daemon   "Servico local do Agent Hub: sessoes, runs, aprovacoes, agendamentos, MCP, terminais e API WebSocket"
criar agent-hub-web      "Interface do Agent Hub em Vue 3, a mesma para navegador, celular e desktop"
criar agent-hub-agents   "Dados do Agent Hub: perfis, papeis, skills, workflows, precos, politicas e conectores MCP"
criar agent-hub-desktop  "Casca desktop do Agent Hub em Tauri 2, com build cruzado para Windows e Linux"
criar agent-hub-relay    "Ponte remota do Agent Hub com cifra ponta a ponta"
criar agent-hub-channels "Canais externos do Agent Hub, comecando pelo Telegram"
criar agent-hub-docs     "Planejamento e decisoes de arquitetura do Agent Hub"
rm -f /tmp/criar-repo.json
