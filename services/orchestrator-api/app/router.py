from dataclasses import dataclass


@dataclass
class RouteResult:
    worker_type: str


DEV_KEYWORDS = {"api", "backend", "frontend", "site", "app", "codigo", "code"}
CONTENT_KEYWORDS = {"conteudo", "texto", "roteiro", "video", "artigo"}
MARKETING_KEYWORDS = {"ads", "campanha", "mkt", "marketing", "crm"}
OPS_KEYWORDS = {"deploy", "docker", "server", "vps", "infra", "ops"}


def route_command(text: str) -> RouteResult:
    normalized = text.lower()

    if any(keyword in normalized for keyword in OPS_KEYWORDS):
        return RouteResult(worker_type="ops")

    if any(keyword in normalized for keyword in DEV_KEYWORDS):
        return RouteResult(worker_type="dev")

    if any(keyword in normalized for keyword in CONTENT_KEYWORDS):
        return RouteResult(worker_type="content")

    if any(keyword in normalized for keyword in MARKETING_KEYWORDS):
        return RouteResult(worker_type="marketing")

    return RouteResult(worker_type="general")
