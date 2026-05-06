FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

RUN pip install --no-cache-dir "websockets>=16,<17"

COPY apps/discord-gateway /app/apps/discord-gateway

ENV PYTHONPATH=/app/apps/discord-gateway

CMD ["python", "-m", "discord_gateway.main"]
