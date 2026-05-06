FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY pyproject.toml README.md /app/
COPY apps /app/apps
COPY packages /app/packages

RUN pip install --no-cache-dir -e .

CMD ["python", "-m", "lifeos_worker.worker"]
