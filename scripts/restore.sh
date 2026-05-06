#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: scripts/restore.sh <backup-tar-gz>" >&2
  exit 2
fi

archive="$1"
test -f "$archive"
tar -tzf "$archive" >/dev/null
echo "restore dry-run ok for ${archive}"
echo "Phase 0 restore does not write files automatically."
