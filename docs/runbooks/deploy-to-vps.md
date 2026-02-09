# Runbook: Deploy do Mac para VPS (rsync)

## Pre-requisitos

- Acesso SSH na VPS.
- rsync instalado no Mac.

## Passo unico (sincroniza e depois executa)

```bash
VPS_HOST=129.121.34.228 \
VPS_PORT=22022 \
VPS_USER=root \
VPS_PATH=/opt/agent-platform \
./scripts/deploy/rsync_to_vps.sh
```

Depois:

```bash
ssh -p 22022 root@129.121.34.228
cd /opt/agent-platform
make up
```

## Observacoes

- O script remove arquivos na VPS que nao existem mais no Mac (rsync --delete).
- As sessoes do WhatsApp nao sao enviadas.
