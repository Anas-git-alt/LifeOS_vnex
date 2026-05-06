FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY pyproject.toml README.md /app/
COPY apps /app/apps
COPY packages /app/packages

RUN pip install --no-cache-dir -e .
RUN chmod +x /app/apps/api/entrypoint.sh

EXPOSE 8000

CMD ["/app/apps/api/entrypoint.sh"]
