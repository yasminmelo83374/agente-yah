from dataclasses import dataclass


@dataclass
class PolicyResult:
    risk_level: str
    required_confirmations: int


DESTRUCTIVE_KEYWORDS = {
    " rm ",
    " delete ",
    " drop ",
    " truncate ",
    " reset ",
    " reboot ",
    " restart ",
}

CRITICAL_KEYWORDS = {
    "deploy",
    "production",
    "prod",
    "secret",
    "senha",
    "token",
    "env",
    "migration",
    "migracao",
    "database",
    "banco",
}


def classify_command(text: str) -> PolicyResult:
    # Regra simples por palavras-chave (MVP). Evoluiremos para politicas por contexto.
    normalized = f" {text.lower()} "

    if any(keyword in normalized for keyword in DESTRUCTIVE_KEYWORDS):
        return PolicyResult(risk_level="destructive", required_confirmations=2)

    if any(keyword in normalized for keyword in CRITICAL_KEYWORDS):
        return PolicyResult(risk_level="critical", required_confirmations=1)

    return PolicyResult(risk_level="safe", required_confirmations=0)
