#!/usr/bin/env bash
set -euo pipefail

REPO_DIR=${1:-}
TITLE=${2:-}
BODY=${3:-""}

if [[ -z "$REPO_DIR" || -z "$TITLE" ]]; then
  echo "Uso: ./scripts/github/create_pr.sh <repo_dir> <titulo> [corpo]"
  exit 1
fi

cd "$REPO_DIR"

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI nao encontrado. Instale o GitHub CLI e autentique com: gh auth login"
  exit 1
fi

gh pr create --title "$TITLE" --body "$BODY"
