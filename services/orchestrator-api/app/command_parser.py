from dataclasses import dataclass


@dataclass
class ParsedCommand:
    raw: str
    shell_command: str | None


def parse_command(text: str) -> ParsedCommand:
    # Permite execucao explicita via prefixo "cmd:"
    normalized = text.strip()
    if normalized.lower().startswith("cmd:"):
        return ParsedCommand(raw=text, shell_command=normalized[4:].strip())
    return ParsedCommand(raw=text, shell_command=None)
