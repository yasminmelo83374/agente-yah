# Mac Runner

Runner local para executar tarefas no Mac quando autorizado.

## Modos

- `OFF`: sem execucao local.
- `ON_SUPERVISED`: execucao local apenas com aprovacao.
- `ON_AUTONOMOUS`: reservado para fase futura.

## Uso local

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
RUNNER_TOKEN=seu_token_aqui PYTHONPATH=. python -m app.main --port 9090
```

## Allowlist

Edite `allowlist.json` para definir comandos e pastas permitidas.
