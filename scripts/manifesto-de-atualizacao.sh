#!/usr/bin/env bash
# Gera o latest.json que o app de desktop consulta para achar, conferir e instalar a versao nova.
# Uso: manifesto-de-atualizacao.sh VERSAO PASTA_DOS_ARTEFATOS [ARQUIVO_DE_NOTAS]
set -euo pipefail
VERSAO="$1"
PASTA="$2"
NOTAS="${3:-}"
INSTALADOR="agent-hub-desktop-${VERSAO}-windows-x64-setup.exe"

if [ ! -f "$PASTA/$INSTALADOR.sig" ]; then
  echo "sem $INSTALADOR.sig: latest.json nao gerado, o app nao vai achar esta versao sozinho" >&2
  exit 0
fi

node --input-type=module - "$VERSAO" "$PASTA" "$INSTALADOR" "$NOTAS" <<'JS'
import { existsSync, readFileSync, writeFileSync } from 'node:fs'
const [versao, pasta, instalador, notas] = process.argv.slice(2)
const manifesto = {
  version: versao,
  notes: notas && existsSync(notas) ? readFileSync(notas, 'utf8').trim() : '',
  pub_date: new Date().toISOString(),
  platforms: {
    'windows-x86_64': {
      signature: readFileSync(`${pasta}/${instalador}.sig`, 'utf8').trim(),
      url: `https://github.com/raylison100/agent-hub/releases/download/v${versao}/${instalador}`,
    },
  },
}
writeFileSync(`${pasta}/latest.json`, JSON.stringify(manifesto, null, 2) + '\n')
console.log(`latest.json gerado para ${versao}`)
JS
