import json
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Optional

DEFAULT_ALLOWLIST = {
    "allowed_commands": ["ls", "pwd", "whoami", "python", "pip", "git"],
    "allowed_paths": [],
}


@dataclass
class Allowlist:
    allowed_commands: list[str]
    allowed_paths: list[str]


def load_allowlist(path: Optional[Path]) -> Allowlist:
    if path is None or not path.exists():
        return Allowlist(**DEFAULT_ALLOWLIST)

    data = json.loads(path.read_text())
    return Allowlist(
        allowed_commands=list(data.get("allowed_commands", [])),
        allowed_paths=list(data.get("allowed_paths", [])),
    )


def is_command_allowed(command: str, allowed_commands: Iterable[str]) -> bool:
    return any(command == item or command.startswith(f"{item} ") for item in allowed_commands)


def is_path_allowed(path: str, allowed_paths: Iterable[str]) -> bool:
    if not allowed_paths:
        return True
    return any(path.startswith(prefix) for prefix in allowed_paths)
