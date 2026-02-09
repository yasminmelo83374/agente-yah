# Politica de Seguranca

## Modos do runner local

- `OFF`: agente sem acesso local.
- `ON_SUPERVISED`: acesso local com aprovacao para acoes criticas.
- `ON_AUTONOMOUS`: reservado para fase futura, com escopo estrito.

## Controles obrigatorios

- Allowlist de caminhos e comandos.
- Auditoria de comando, saida e artefatos.
- Timebox de sessao de autonomia local.
- Revogacao imediata via kill switch.
- Dupla confirmacao para acoes destrutivas.
