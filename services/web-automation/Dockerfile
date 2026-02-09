FROM mcr.microsoft.com/playwright/python:v1.49.1-jammy

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

ENV WEB_ARTIFACTS_DIR=/app/artifacts

EXPOSE 9095

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "9095"]
