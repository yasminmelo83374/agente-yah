# Runbook Mac Runner

## Iniciar runner

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r services/mac-runner/requirements.txt
RUNNER_TOKEN=seu_token_aqui PYTHONPATH=services/mac-runner python -m app.main --port 9090
```

## Mudar modo

```bash
curl -X POST http://127.0.0.1:9090/mode -H 'Content-Type: application/json' -d '{"mode":"ON_SUPERVISED"}'
```

## Status

```bash
curl http://127.0.0.1:9090/status
```

## Allowlist

Edite `services/mac-runner/allowlist.json` para adicionar comandos ou pastas.
