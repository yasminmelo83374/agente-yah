import argparse
import shlex
import sys

import requests


def send_command(api_url: str, text: str, actor_id: str = "owner") -> None:
    payload = {"source": "cli", "text": text, "actor_id": actor_id}
    response = requests.post(f"{api_url}/commands", json=payload, timeout=30)
    response.raise_for_status()
    data = response.json()

    print(
        f"job_id={data['job_id']} status={data['status']} "
        f"risk={data['risk_level']} worker={data['worker_type']}"
    )
    print(data["message"])


def approve_job(api_url: str, job_id: int, actor_id: str = "owner") -> None:
    payload = {"actor_id": actor_id}
    response = requests.post(f"{api_url}/approvals/{job_id}", json=payload, timeout=30)
    response.raise_for_status()
    data = response.json()
    print(
        f"job_id={data['id']} status={data['status']} "
        f"confirmacoes={data['confirmations_done']}/{data['required_confirmations']}"
    )


def set_kill_switch(api_url: str, enabled: bool, actor_id: str = "owner") -> None:
    payload = {"enabled": enabled, "actor_id": actor_id}
    response = requests.post(f"{api_url}/control/kill-switch", json=payload, timeout=30)
    response.raise_for_status()
    data = response.json()
    status = "ON" if data["kill_switch_enabled"] else "OFF"
    print(f"kill_switch={status}")


def job_status(api_url: str, job_id: int) -> None:
    response = requests.get(f"{api_url}/jobs/{job_id}", timeout=30)
    response.raise_for_status()
    data = response.json()

    print(f"id={data['id']} status={data['status']} risk={data['risk_level']}")
    if data.get("explanation"):
        print(f"explicacao: {data['explanation']}")
    if data.get("proposed_fix"):
        print(f"plano: {data['proposed_fix']}")


def run_chat(api_url: str, actor_id: str) -> None:
    print("agent chat iniciado. Use /exit para sair.")
    print("Comandos: /status <id> | /approve <id> | /approve2 <id> | /killon | /killoff")

    while True:
        try:
            line = input("agent> ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nencerrando chat.")
            return

        if not line:
            continue

        if line == "/exit":
            print("ate logo.")
            return

        try:
            # Interpretacao simples de comandos locais do CLI.
            if line.startswith("/status"):
                parts = shlex.split(line)
                job_status(api_url, int(parts[1]))
                continue

            if line.startswith("/approve2"):
                parts = shlex.split(line)
                approve_job(api_url, int(parts[1]), actor_id)
                continue

            if line.startswith("/approve"):
                parts = shlex.split(line)
                approve_job(api_url, int(parts[1]), actor_id)
                continue

            if line == "/killon":
                set_kill_switch(api_url, True, actor_id)
                continue

            if line == "/killoff":
                set_kill_switch(api_url, False, actor_id)
                continue

            send_command(api_url, line, actor_id)
        except Exception as exc:  # pragma: no cover - UX do CLI
            print(f"erro: {exc}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="CLI do Agent Platform")
    parser.add_argument("--api-url", default="http://localhost:8080", help="URL da API")
    parser.add_argument("--actor-id", default="owner", help="Identificador do aprovador")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    run_chat(args.api_url, args.actor_id)
    return 0


if __name__ == "__main__":
    sys.exit(main())
