import os
from typing import Any

import requests

from .config import settings


class LLMError(RuntimeError):
    pass


def _api_url(model: str) -> str:
    return f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"


def generate_reply(prompt: str, system: str) -> str:
    api_key = settings.gemini_api_key
    model = settings.gemini_model
    if not api_key or not model:
        raise LLMError("Gemini nao configurado")

    payload: dict[str, Any] = {
        "contents": [
            {
                "role": "user",
                "parts": [{"text": prompt}],
            }
        ],
        "systemInstruction": {
            "role": "system",
            "parts": [{"text": system}],
        },
        "generationConfig": {
            "temperature": 0.2,
            "maxOutputTokens": 1024,
            "topP": 0.9,
        },
    }

    response = requests.post(
        _api_url(model),
        params={"key": api_key},
        json=payload,
        timeout=30,
    )
    if not response.ok:
        raise LLMError(f"Gemini erro {response.status_code}: {response.text}")

    data = response.json()
    candidates = data.get("candidates", [])
    if not candidates:
        raise LLMError("Gemini sem resposta")

    parts = candidates[0].get("content", {}).get("parts", [])
    if not parts:
        raise LLMError("Gemini sem conteudo")

    text = parts[0].get("text", "").strip()
    if not text:
        raise LLMError("Gemini retornou vazio")

    return text
