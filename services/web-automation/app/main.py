import os
import time
from pathlib import Path

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from playwright.sync_api import sync_playwright

ARTIFACTS_DIR = Path(os.getenv("WEB_ARTIFACTS_DIR", "./artifacts"))
ARTIFACTS_DIR.mkdir(parents=True, exist_ok=True)


class ScreenshotRequest(BaseModel):
    url: str = Field(..., description="URL para abrir")
    wait_ms: int = Field(default=2000, ge=0, le=20000)


app = FastAPI(title="Web Automation", version="0.1.0")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/screenshot")
def screenshot(payload: ScreenshotRequest) -> dict:
    filename = f"shot_{int(time.time())}.png"
    output = ARTIFACTS_DIR / filename

    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page()
        try:
            page.goto(payload.url, timeout=15000)
            page.wait_for_timeout(payload.wait_ms)
            page.screenshot(path=str(output), full_page=True)
        except Exception as exc:
            raise HTTPException(status_code=500, detail=str(exc)) from exc
        finally:
            browser.close()

    return {"status": "ok", "path": str(output)}
