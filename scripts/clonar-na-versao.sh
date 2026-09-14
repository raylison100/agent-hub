#!/usr/bin/env bash
# No GitHub Actions, clona os outros repositorios na tag que disparou o workflow, ou na main quando o disparo e por branch.
set -euo pipefail
DONO="${GITHUB_REPOSITORY_OWNER:-raylison100}"
REF="main"
[ "${GITHUB_REF_TYPE:-}" = "tag" ] && REF="$GITHUB_REF_NAME"
for pasta in core daemon web agents desktop relay channels docs; do
  git clone -q "https://github.com/${DONO}/agent-hub-${pasta}.git" "$pasta"
  git -C "$pasta" checkout -q "$REF"
  echo "$pasta em $REF: $(git -C "$pasta" log -1 --format='%h %s')"
done
