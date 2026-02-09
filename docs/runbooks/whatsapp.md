# Runbook WhatsApp (QR)

## Subir gateway

```bash
make up-whatsapp
```

## Obter QR

```bash
make logs-whatsapp
```

## Problemas comuns

- Sessao expirada: remova a pasta `services/whatsapp-gateway/sessions` e reconecte.
- Mensagens nao chegam: confira `WHATSAPP_OWNER_JID` e logs do container.

## Comandos disponiveis

- texto livre: cria job
- `/status <job_id>`: consulta status
- `/approve <job_id>`: aprova etapa 1 (repita para dupla confirmacao)
- `/killon` e `/killoff`: liga/desliga kill switch
- `/whoami`: mostra o JID do seu numero
