#!/usr/bin/env bash
set -euo pipefail

alembic -c apps/api/alembic.ini upgrade head
exec uvicorn lifeos_api.main:app --host 0.0.0.0 --port 8000
