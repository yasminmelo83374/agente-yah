import subprocess
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

from .config import LOG_DIR


@dataclass
class ExecResult:
    exit_code: int
    stdout: str
    stderr: str
    duration_ms: int


def run_command(command: str, workdir: Optional[Path], timeout_s: int = 60) -> ExecResult:
    start = time.time()
    process = subprocess.run(
        command,
        shell=True,
        cwd=str(workdir) if workdir else None,
        capture_output=True,
        text=True,
        timeout=timeout_s,
    )
    duration_ms = int((time.time() - start) * 1000)
    return ExecResult(
        exit_code=process.returncode,
        stdout=process.stdout.strip(),
        stderr=process.stderr.strip(),
        duration_ms=duration_ms,
    )


def write_log(job_id: int, result: ExecResult) -> Path:
    log_path = LOG_DIR / f"job_{job_id}.log"
    log_path.write_text(
        f"exit_code={result.exit_code}\n"
        f"duration_ms={result.duration_ms}\n"
        f"stdout:\n{result.stdout}\n\n"
        f"stderr:\n{result.stderr}\n"
    )
    return log_path
