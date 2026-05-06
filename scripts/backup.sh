#!/usr/bin/env bash
set -euo pipefail

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "vault/system/backups/${stamp}"
tar -czf "vault/system/backups/${stamp}/vault-safe.tar.gz" \
  --exclude='vault/raw' \
  --exclude='vault/system/backups' \
  --exclude='vault/system/snapshots' \
  vault

echo "backup written to vault/system/backups/${stamp}/vault-safe.tar.gz"
