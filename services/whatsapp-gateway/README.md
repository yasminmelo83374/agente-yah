# WhatsApp Gateway (QR)

Gateway via QR usando Baileys. Usado para enviar comandos ao orquestrador.

## Uso local

```bash
cd services/whatsapp-gateway
npm install
ORCHESTRATOR_API_URL=http://localhost:8080 npm start
```

## Variaveis

- `ORCHESTRATOR_API_URL`: URL da API (default: http://localhost:8080)
- `WHATSAPP_SESSION_DIR`: pasta de sessao (default: ./sessions)
- `WHATSAPP_OWNER_JID`: restringe quem pode enviar comandos
