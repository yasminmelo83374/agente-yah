#!/usr/bin/env bash
set -euo pipefail

# Uso:
# VPS_HOST=example VPS_PORT=22022 VPS_USER=root VPS_PATH=/opt/agent-platform \
#   ./scripts/deploy/rsync_to_vps.sh

VPS_HOST=${VPS_HOST:-}
VPS_PORT=${VPS_PORT:-22022}
VPS_USER=${VPS_USER:-root}
VPS_PATH=${VPS_PATH:-}

if [[ -z "$VPS_HOST" || -z "$VPS_PATH" ]]; then
  echo "Uso: VPS_HOST=... VPS_PORT=22022 VPS_USER=root VPS_PATH=/opt/agent-platform ./scripts/deploy/rsync_to_vps.sh"
  exit 1
fi

RSYNC_EXCLUDES=(
  --exclude ".git/"
  --exclude ".venv/"
  --exclude "node_modules/"
  --exclude "services/whatsapp-gateway/sessions/"
  --exclude "tmp/"
  --exclude "artifacts/"
)

echo "Sincronizando para ${VPS_USER}@${VPS_HOST}:${VPS_PATH} (porta ${VPS_PORT})"

rsync -avz --delete "${RSYNC_EXCLUDES[@]}" \
  -e "ssh -p ${VPS_PORT}" \
  ./ "${VPS_USER}@${VPS_HOST}:${VPS_PATH}"

cat <<MSG
OK. Agora rode na VPS:
  ssh -p ${VPS_PORT} ${VPS_USER}@${VPS_HOST}
  cd ${VPS_PATH}
  make up
MSG
