# Runbook

## Bootstrap

```bash
cp .env.example .env
python3 scripts/doctor.py
docker compose up --build
```

## Health

- API: `GET /api/health`
- Readiness: `GET /api/readiness`
- WebUI: `http://localhost:5173`

## Failure Policy

Failures should surface in Discord or WebUI. If something cannot be processed safely, write it to the dead-letter store and keep related review items pending.
