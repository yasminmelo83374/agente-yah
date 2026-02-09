# Blueprint v1

## Canais de entrada

- WhatsApp (gateway QR)
- CLI de terminal (`agent chat`)

## Fluxo principal

1. Canal envia comando para o `orchestrator-api`.
2. `policy-engine` classifica risco.
3. Se critico/destrutivo, job vai para aprovacao.
4. Com aprovacao, job entra na fila (`Redis + Celery`).
5. Worker executa, registra status e evidencia (se kill switch estiver OFF).
6. Painel exibe timeline e auditoria.

## Componentes

- `orchestrator-api`: recepcao de comandos e politicas.
- `whatsapp-gateway`: QR e mensagens.
- `agent-cli`: chat no terminal.
- `mac-runner`: execucao local autorizada.

## Regras de seguranca

- Sem instrucao explicita: perguntar.
- Acao critica: aprovacao obrigatoria.
- Acao destrutiva: dupla confirmacao.
- Kill switch bloqueia execucao automaticamente.
- Kill switch global e por agente (proxima fase).
