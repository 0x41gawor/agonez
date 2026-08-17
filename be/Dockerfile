FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

RUN groupadd --system --gid 10001 agonez \
    && useradd --system --uid 10001 --gid agonez --home-dir /nonexistent agonez

COPY pyproject.toml requirements.lock README.md ./
COPY src ./src

RUN python -m pip install --upgrade pip \
    && python -m pip install --requirement requirements.lock \
    && python -m pip install --no-deps . \
    && mkdir -p /app/media/exercises /app/media/muscles \
    && chown -R agonez:agonez /app

USER agonez

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health/ready', timeout=2)"]

CMD ["sh", "-c", "python -m agonez_api.migrations && exec uvicorn agonez_api.main:app --host 0.0.0.0 --port 8000 --workers ${WEB_CONCURRENCY:-1} --proxy-headers --forwarded-allow-ips ${FORWARDED_ALLOW_IPS:-127.0.0.1}"]
