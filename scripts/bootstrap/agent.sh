#!/usr/bin/env bash
set -euo pipefail

CMD=${1:-}
shift || true

case "$CMD" in
  chat)
    PYTHONPATH="services/agent-cli${PYTHONPATH:+:$PYTHONPATH}" python -m agent_cli.main "$@"
    ;;
  *)
    echo "Uso: ./scripts/bootstrap/agent.sh chat [--api-url URL] [--actor-id ID]"
    exit 1
    ;;
esac
