import json
import os
from pathlib import Path
import sys

import requests

API_KEY = os.getenv("GEMINI_API_KEY")
MODEL = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")

if not API_KEY:
    print("GEMINI_API_KEY nao definido")
    sys.exit(1)

SOURCE_DIR = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("./content")
OUTPUT = Path("./artifacts/knowledge_base.jsonl")
OUTPUT.parent.mkdir(parents=True, exist_ok=True)


def read_text_files(root: Path):
    for path in root.rglob("*"):
        if path.is_file() and path.suffix.lower() in {".md", ".txt"}:
            yield path


def summarize(text: str) -> str:
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent"
    payload = {
        "contents": [{"role": "user", "parts": [{"text": text[:6000]}]}],
        "generationConfig": {"temperature": 0.2, "maxOutputTokens": 256},
    }
    resp = requests.post(url, params={"key": API_KEY}, json=payload, timeout=30)
    resp.raise_for_status()
    data = resp.json()
    return data["candidates"][0]["content"]["parts"][0]["text"].strip()


with OUTPUT.open("w", encoding="utf-8") as f:
    for path in read_text_files(SOURCE_DIR):
        content = path.read_text(encoding="utf-8", errors="ignore")
        if not content.strip():
            continue
        summary = summarize(content)
        record = {
            "file": str(path),
            "summary": summary,
        }
        f.write(json.dumps(record, ensure_ascii=False) + "\n")

print(f"Base gerada em {OUTPUT}")
