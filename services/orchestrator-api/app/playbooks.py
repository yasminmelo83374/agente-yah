from dataclasses import dataclass


@dataclass
class PlaybookResult:
    explanation: str
    proposed_fix: str


def _dev_playbook(text: str) -> PlaybookResult:
    return PlaybookResult(
        explanation=(
            "Plano tecnico de desenvolvimento: vou levantar requisitos, mapear stack, "
            "definir arquitetura, implementar, testar e disponibilizar com rollback."
        ),
        proposed_fix=(
            "1) Levantar requisitos e fluxos. "
            "2) Criar esqueleto do projeto. "
            "3) Implementar features. "
            "4) Testes e validações. "
            "5) Deploy supervisionado."
        ),
    )


def _content_playbook(text: str) -> PlaybookResult:
    return PlaybookResult(
        explanation=(
            "Plano de conteudo: coleta de materiais, organizacao em base, resumo estruturado "
            "e entrega no canal escolhido."
        ),
        proposed_fix=(
            "1) Coletar fontes autorizadas. "
            "2) Extrair e organizar por topicos. "
            "3) Gerar resumos e FAQ. "
            "4) Publicar/entregar."
        ),
    )


def _marketing_playbook(text: str) -> PlaybookResult:
    return PlaybookResult(
        explanation=(
            "Plano de marketing: diagnostico de objetivos, definicao de campanha, criacao de assets "
            "e automacoes, com monitoramento de resultados."
        ),
        proposed_fix=(
            "1) Definir objetivo e publico. "
            "2) Criar assets e mensagens. "
            "3) Configurar automacoes. "
            "4) Medir e ajustar."
        ),
    )


def _ops_playbook(text: str) -> PlaybookResult:
    return PlaybookResult(
        explanation=(
            "Plano de operacao: checar infraestrutura, preparar deploy, executar com monitoramento "
            "e validar logs/healthchecks."
        ),
        proposed_fix=(
            "1) Checar ambiente. "
            "2) Preparar backups/rollback. "
            "3) Deploy ou ajuste. "
            "4) Validar saude."
        ),
    )


def _general_playbook(text: str) -> PlaybookResult:
    return PlaybookResult(
        explanation=(
            "Plano geral: entender o pedido, decompor tarefas, executar com seguranca e revisar resultados."
        ),
        proposed_fix=(
            "1) Entender objetivo. "
            "2) Dividir em passos. "
            "3) Executar e validar."
        ),
    )


def build_playbook(worker_type: str, text: str) -> PlaybookResult:
    if worker_type == "dev":
        return _dev_playbook(text)
    if worker_type == "content":
        return _content_playbook(text)
    if worker_type == "marketing":
        return _marketing_playbook(text)
    if worker_type == "ops":
        return _ops_playbook(text)
    return _general_playbook(text)
