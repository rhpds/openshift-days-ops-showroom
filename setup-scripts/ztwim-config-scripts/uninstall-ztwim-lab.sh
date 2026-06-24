#!/usr/bin/env bash
# Backward-compatible wrapper — use configure-ztwim-postgresql-lab.sh cleanup instead.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/configure-ztwim-postgresql-lab.sh" cleanup
