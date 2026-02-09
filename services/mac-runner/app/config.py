import os
from pathlib import Path

RUNNER_TOKEN = os.getenv("RUNNER_TOKEN", "")
ALLOWLIST_FILE = Path(os.getenv("RUNNER_ALLOWLIST", ""))
LOG_DIR = Path(os.getenv("RUNNER_LOG_DIR", "./logs"))
LOG_DIR.mkdir(parents=True, exist_ok=True)
