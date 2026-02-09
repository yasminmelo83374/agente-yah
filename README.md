# Agent Platform (MVP v1)

Plataforma para orquestrar agentes com foco em produtividade, execucao supervisionada e auditoria.

## O que ja esta implementado

- `orchestrator-api` (FastAPI) com:
  - entrada de comandos (WhatsApp/CLI via mesmo endpoint)
  - classificacao de risco (`safe`, `critical`, `destructive`)
  - fluxo de aprovacao para acoes criticas
  - dupla confirmacao para acoes destrutivas
  - trilha basica de auditoria em banco
- `worker` (Celery) para execucao assincrona de jobs
- `agent chat` (CLI) para conversa no terminal
- `docker-compose` com Postgres, Redis, API e Worker
- `whatsapp-gateway` (QR) para comandos e aprovacoes
- `mac-runner` (local) com modos `OFF`, `ON_SUPERVISED`, `ON_AUTONOMOUS`
- estrutura inicial de monorepo para evolucao de subagentes e painel

## Estrutura

- `services/orchestrator-api`: API principal + policy engine + aprovacoes
- `services/agent-cli`: comando `agent chat`
- `services/panel-web`: painel web com timeline e kill switch
- `services/whatsapp-gateway`: gateway WhatsApp (QR)
- `services/mac-runner`: runner local do Mac
- `workers/*`: espacos para workers especializados
- `docs/`: arquitetura, politicas e runbooks

## Subindo localmente

```bash
make up
make logs
```

A API fica em `http://localhost:8080`.
O painel fica em `http://localhost:3000`.

## Usando o chat no terminal

Em outro terminal:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r services/agent-cli/requirements.txt
PYTHONPATH=services/agent-cli python -m agent_cli.main --api-url http://localhost:8080
```

Ou usando o wrapper:

```bash
./scripts/bootstrap/agent.sh chat --api-url http://localhost:8080
```

Comandos no chat:

- texto livre: cria job
- `/status <job_id>`: consulta status
- `/approve <job_id>`: aprova etapa 1
- `/approve2 <job_id>`: aprova etapa 2 (quando destrutivo)
- `/killon`: ativa kill switch
- `/killoff`: desativa kill switch
- `/exit`: sair

Execucao explicita de comando local (safe):

- `cmd: ls -la`

## WhatsApp gateway (QR)

```bash
make up-whatsapp
```

Depois, acompanhe o QR no log do container:

```bash
make logs-whatsapp
```

Comandos no WhatsApp:

- texto livre: cria job
- `/status <job_id>`: consulta status
- `/approve <job_id>`: aprova etapa 1 (e 2 se repetir)
- `/killon` e `/killoff`: liga/desliga kill switch
- `/whoami`: mostra seu JID para configurar dono

Execucao explicita:

- `cmd: ls -la`

## Runner local (Mac)

O runner local inicia em modo `OFF`. Para iniciar em modo supervisionado:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r services/mac-runner/requirements.txt
RUNNER_TOKEN=seu_token_aqui PYTHONPATH=services/mac-runner python -m app.main --port 9090
```

Para conectar o runner ao orquestrador, exporte as variaveis:

```bash
export MAC_RUNNER_URL=http://host.docker.internal:9090
export MAC_RUNNER_TOKEN=seu_token_aqui
```

## LLM (Gemini)

Adicionar no `.env`:

```
GEMINI_API_KEY=...
GEMINI_MODEL=gemini-2.5-flash
```

## Audio (WhatsApp)

Para transcrever audio via OpenAI, adicione no `.env`:

```
OPENAI_API_KEY=...
OPENAI_TRANSCRIBE_MODEL=gpt-4o-mini-transcribe
```

Depois, envie audio no WhatsApp. O agente responde com a transcricao antes de executar.

## Web Automation (Playwright)

Subir servico opcional:

```bash
docker compose -f docker-compose.yml -f infra/compose/docker-compose.web.yml --profile web up --build -d
```

Endpoint de screenshot:

```
POST http://localhost:9095/screenshot
```

## GitHub

Scripts locais:

```bash
./scripts/github/commit_push.sh <repo_dir> \"mensagem\"
./scripts/github/create_pr.sh <repo_dir> \"titulo\" \"corpo\"
```

## Pipeline de conteudo (treino de agente)

```bash
python3 scripts/content/build_kb.py ./content
```

## Subagentes (v1)

- `dev`, `content`, `marketing`, `ops`, `general` (roteamento automatico).

## Allowlist (Mac Runner)

Edite `services/mac-runner/allowlist.json` para permitir comandos e pastas.

## Deploy para VPS (rsync)

```bash
VPS_HOST=129.121.34.228 \
VPS_PORT=22022 \
VPS_USER=root \
VPS_PATH=/opt/agent-platform \
./scripts/deploy/rsync_to_vps.sh
```

## Sync automatico Mac -> VPS (launchd)

```bash
./scripts/deploy/launchd_install.sh
```


## Proximas fases

1. Construir painel web real com timeline, aprovacoes e kill switch.
2. Implementar execucao real no `mac-runner` com allowlist e auditoria.
3. Implementar execução real de tarefas por worker especializado.
