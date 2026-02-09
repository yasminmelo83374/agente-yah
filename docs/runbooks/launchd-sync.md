# Runbook: Auto-sync Mac -> VPS (launchd)

## Instalar

```bash
./scripts/deploy/launchd_install.sh
```

## Desativar

```bash
launchctl unload ~/Library/LaunchAgents/com.agentplatform.sync.plist
```

## Observacoes

- O sync roda a cada 10 minutos.
- Logs ficam em `artifacts/launchd-sync.log`.
- O script usa rsync e depende de SSH configurado.
