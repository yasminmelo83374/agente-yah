import os
from typing import Optional

import requests

from .config import settings


class TranscribeError(RuntimeError):
    pass


def transcribe_audio(file_path: str, mime_type: Optional[str] = None) -> str:
    api_key = settings.openai_api_key
    model = settings.openai_transcribe_model or "gpt-4o-mini-transcribe"
    if not api_key:
        raise TranscribeError("OPENAI_API_KEY nao configurado")

    url = "https://api.openai.com/v1/audio/transcriptions"
    headers = {"Authorization": f"Bearer {api_key}"}

    with open(file_path, "rb") as f:
        files = {
            "file": (os.path.basename(file_path), f, mime_type or "application/octet-stream"),
        }
        data = {
            "model": model,
            "response_format": "text",
        }
        resp = requests.post(url, headers=headers, files=files, data=data, timeout=60)

    if not resp.ok:
        raise TranscribeError(f"OpenAI erro {resp.status_code}: {resp.text}")

    text = resp.text.strip()
    if not text:
        raise TranscribeError("Transcricao vazia")
    return text
