# Local Setup

## Requisitos

- Docker + Docker Compose
- Python 3.11+ (API em container)
- Python 3.9+ (CLI local)

## Passos

```bash
make up
make logs
```

Teste de saude:

```bash
curl http://localhost:8080/health
```

Abrir painel placeholder:

- http://localhost:3000
