FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8081

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

RUN useradd --create-home --uid 1000 appuser \
    && mkdir -p /data \
    && chown -R 1000:1000 /app /data

USER 1000:1000

EXPOSE 8081

CMD ["sh", "-c", "uvicorn app:app --host 0.0.0.0 --port ${PORT:-8081}"]
