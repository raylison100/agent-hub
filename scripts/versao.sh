#!/usr/bin/env bash
# Troca a versao do Agent Hub em todos os pacotes, commita e cria a tag vVERSAO nos nove repositorios; a tag da raiz dispara a Release.
set -euo pipefail
VERSAO="${1:-}"
[[ "$VERSAO" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "uso: make versao VERSAO=0.2.0" >&2; exit 1; }
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TAG="v$VERSAO"
SUBS="core daemon web agents desktop relay channels docs"

for r in $SUBS .; do
  d="$ROOT/$r"
  [ -d "$d/.git" ] || { echo "falta o repositorio $r; rode clonar-tudo.sh" >&2; exit 1; }
  [ -z "$(git -C "$d" status --porcelain)" ] || { echo "$r tem mudanca nao commitada" >&2; exit 1; }
  [ "$(git -C "$d" rev-parse --abbrev-ref HEAD)" = "main" ] || { echo "$r nao esta na main" >&2; exit 1; }
  git -C "$d" fetch -q origin main --tags
  [ "$(git -C "$d" rev-parse main)" = "$(git -C "$d" rev-parse origin/main)" ] || { echo "$r esta diferente do GitHub; faca pull ou push antes" >&2; exit 1; }
  if git -C "$d" rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then echo "$r ja tem a tag $TAG" >&2; exit 1; fi
done

node --input-type=module - "$ROOT" "$VERSAO" <<'JS'
import { readFileSync, writeFileSync } from 'node:fs'
const [root, versao] = process.argv.slice(2)
for (const r of ['core', 'daemon', 'web', 'relay', 'channels', 'desktop']) {
  const p = `${root}/${r}/package.json`
  const d = JSON.parse(readFileSync(p, 'utf8'))
  d.version = versao
  writeFileSync(p, JSON.stringify(d, null, 2) + '\n')
}
const tauri = `${root}/desktop/src-tauri/tauri.conf.json`
const t = JSON.parse(readFileSync(tauri, 'utf8'))
t.version = versao
writeFileSync(tauri, JSON.stringify(t, null, 2) + '\n')
const cargo = `${root}/desktop/src-tauri/Cargo.toml`
writeFileSync(cargo, readFileSync(cargo, 'utf8').replace(/^version = ".*"$/m, `version = "${versao}"`))
const lock = `${root}/desktop/src-tauri/Cargo.lock`
writeFileSync(lock, readFileSync(lock, 'utf8').replace(/(name = "agent-hub-desktop"\nversion = )".*"/, `$1"${versao}"`))
JS

for r in $SUBS .; do
  d="$ROOT/$r"
  if [ -n "$(git -C "$d" status --porcelain)" ]; then
    git -C "$d" add -A
    git -C "$d" commit -q -m "Versao $VERSAO"
  fi
  git -C "$d" tag -a "$TAG" -m "Agent Hub $VERSAO"
done

for r in $SUBS; do
  git -C "$ROOT/$r" push -q origin main "$TAG"
  echo "enviado $r $TAG"
done
git -C "$ROOT" push -q origin main "$TAG"
echo "enviado agent-hub $TAG: o workflow Release monta, testa e publica o pacote"
echo "acompanhe em https://github.com/raylison100/agent-hub/actions"
