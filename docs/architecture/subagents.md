# Subagentes (v1)

## Tipos

- `dev`: criacao de APIs, apps e codigo.
- `content`: roteiros, textos e organizacao de materiais.
- `marketing`: campanhas, CRM e automacao de marketing.
- `ops`: deploy, infraestrutura e observabilidade.
- `general`: fallback para comandos genericos.

## Roteamento

O orquestrador escolhe o subagente baseado em palavras-chave presentes no comando.

## Futuro

- Roteamento por embeddings.
- Politicas por subagente.
- Templates e playbooks para cada tipo.
