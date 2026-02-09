#!/usr/bin/env bash
set -euo pipefail

REPO_DIR=${1:-}
MESSAGE=${2:-}

if [[ -z "$REPO_DIR" || -z "$MESSAGE" ]]; then
  echo "Uso: ./scripts/github/commit_push.sh <repo_dir> <mensagem>"
  exit 1
fi

cd "$REPO_DIR"

git status --porcelain

git add -A
git commit -m "$MESSAGE"

git push
