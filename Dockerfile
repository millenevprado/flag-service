FROM python:3.11-slim AS builder

WORKDIR /app

RUN pip install --no-cache-dir --upgrade pip==26.2.1 setuptools==84.0.0 wheel==0.48.0

COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

FROM python:3.11-slim AS production

RUN apt-get update && apt-get upgrade -y && \
    rm -rf /var/lib/apt/lists/*

# Production doesn't need pip at runtime (app deps are copied pre-built from the
# builder stage), and pip vendors its own copies of setuptools/msgpack that can
# be vulnerable regardless of pip version — so remove it instead of chasing pins.
RUN python -m pip uninstall -y pip setuptools wheel

RUN groupadd -r appgroup && useradd -r -g appgroup -m appuser

WORKDIR /app

COPY --from=builder /root/.local /home/appuser/.local
COPY --chown=appuser:appgroup . .

ENV PATH=/home/appuser/.local/bin:$PATH \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

USER appuser

EXPOSE 8002

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8002/health')" || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:8002", "app:app"]
