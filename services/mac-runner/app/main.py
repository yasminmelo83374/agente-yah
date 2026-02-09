import argparse
import json
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel, Field

from .allowlist import is_command_allowed, is_path_allowed, load_allowlist
from .config import RUNNER_TOKEN
from .executor import run_command, write_log

STATE_FILE = Path(__file__).resolve().parent / "state.json"
ALLOWED_MODES = {"OFF", "ON_SUPERVISED", "ON_AUTONOMOUS"}


class ModeRequest(BaseModel):
    mode: str = Field(..., description="OFF | ON_SUPERVISED | ON_AUTONOMOUS")


class TaskRequest(BaseModel):
    job_id: int
    command: str
    risk_level: str = "safe"
    workdir: Optional[str] = None


app = FastAPI(title="Mac Runner", version="0.1.0")


def _read_state() -> dict:
    if not STATE_FILE.exists():
        return {"mode": "OFF"}
    return json.loads(STATE_FILE.read_text())


def _write_state(state: dict) -> None:
    STATE_FILE.write_text(json.dumps(state, indent=2))


@app.get("/status")
def status() -> dict:
    return _read_state()


@app.post("/mode")
def set_mode(payload: ModeRequest) -> dict:
    if payload.mode not in ALLOWED_MODES:
        raise HTTPException(status_code=400, detail="Modo invalido")

    state = _read_state()
    state["mode"] = payload.mode
    _write_state(state)
    return state


@app.post("/tasks")
def enqueue_task(
    payload: TaskRequest, x_runner_token: Optional[str] = Header(default=None)
) -> dict:
    state = _read_state()
    if state.get("mode") == "OFF":
        raise HTTPException(status_code=403, detail="Runner local desligado")

    if RUNNER_TOKEN and x_runner_token != RUNNER_TOKEN:
        raise HTTPException(status_code=401, detail="Token invalido")

    allowlist = load_allowlist(Path("allowlist.json"))
    if not is_command_allowed(payload.command, allowlist.allowed_commands):
        raise HTTPException(status_code=403, detail="Comando nao permitido pela allowlist")

    if payload.workdir and not is_path_allowed(payload.workdir, allowlist.allowed_paths):
        raise HTTPException(status_code=403, detail="Pasta nao permitida pela allowlist")

    if state.get("mode") == "ON_SUPERVISED" and payload.risk_level != "safe":
        raise HTTPException(status_code=403, detail="Aprovacao exigida para risco nao seguro")

    result = run_command(payload.command, Path(payload.workdir) if payload.workdir else None)
    log_path = write_log(payload.job_id, result)

    return {
        "status": "executed",
        "job_id": payload.job_id,
        "mode": state.get("mode"),
        "exit_code": result.exit_code,
        "duration_ms": result.duration_ms,
        "log_path": str(log_path),
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Mac Runner")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=9090)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    import uvicorn

    uvicorn.run(app, host=args.host, port=args.port)


if __name__ == "__main__":
    main()
