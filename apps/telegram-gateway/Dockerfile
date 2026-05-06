FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY apps/telegram-gateway /app/apps/telegram-gateway

ENV PYTHONPATH=/app/apps/telegram-gateway

CMD ["python", "-m", "telegram_gateway.main"]
