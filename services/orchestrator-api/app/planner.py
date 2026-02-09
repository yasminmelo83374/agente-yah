from dataclasses import dataclass


@dataclass
class StepPlan:
    title: str
    action: str


def build_steps(worker_type: str, text: str) -> list[StepPlan]:
    if worker_type == "dev":
        return [
            StepPlan("Levantamento de requisitos", "documentar requisitos e stack"),
            StepPlan("Arquitetura", "definir estrutura do projeto"),
            StepPlan("Implementacao", "criar codigo e integrar"),
            StepPlan("Testes", "validar comportamento"),
            StepPlan("Entrega", "preparar deploy supervisionado"),
        ]

    if worker_type == "content":
        return [
            StepPlan("Coleta", "reunir fontes autorizadas"),
            StepPlan("Organizacao", "estruturar base"),
            StepPlan("Resumo", "gerar material final"),
            StepPlan("Entrega", "disponibilizar no canal"),
        ]

    if worker_type == "marketing":
        return [
            StepPlan("Diagnostico", "definir objetivo e publico"),
            StepPlan("Assets", "criar mensagens e criativos"),
            StepPlan("Automacao", "configurar campanhas"),
            StepPlan("Analise", "monitorar e ajustar"),
        ]

    if worker_type == "ops":
        return [
            StepPlan("Saude", "checar ambiente"),
            StepPlan("Backup", "validar rollback"),
            StepPlan("Execucao", "aplicar mudanca"),
            StepPlan("Validacao", "confirmar logs/health"),
        ]

    return [
        StepPlan("Entendimento", "entender o pedido"),
        StepPlan("Execucao", "realizar tarefas"),
        StepPlan("Revisao", "confirmar resultado"),
    ]
