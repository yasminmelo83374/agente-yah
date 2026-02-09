import requests

from .config import settings


class MacRunnerError(RuntimeError):
    pass


def send_to_mac_runner(job_id: int, command: str, risk_level: str) -> dict:
    if not settings.mac_runner_url:
        raise MacRunnerError("MAC_RUNNER_URL nao configurado")

    headers = {"Content-Type": "application/json"}
    if settings.mac_runner_token:
        headers["X-Runner-Token"] = settings.mac_runner_token

    payload = {
        "job_id": job_id,
        "command": command,
        "risk_level": risk_level,
        "workdir": None,
    }

    response = requests.post(
        f"{settings.mac_runner_url}/tasks",
        json=payload,
        headers=headers,
        timeout=30,
    )
    if not response.ok:
        raise MacRunnerError(f"Runner recusou: {response.status_code} {response.text}")

    return response.json()
