#!/usr/bin/env bash
set -euo pipefail

# Ensure expected dirs exist
mkdir -p /app/data /app/raw

BOOTSTRAP=${TOLLTARIFF_BOOTSTRAP:-true}
TOLL_DUTY_URL=${TOLLTARIFF_DUTY_URL:-}

if [[ "$BOOTSTRAP" == "true" ]]; then
  echo "[bootstrap] Starting initial data fetch/import..."
  # Fetch catalogs
  python -m tolltariff.cli fetch-landgroups || true
  python -m tolltariff.cli import-landgroups || true
  python -m tolltariff.cli fetch-fta || true
  python -m tolltariff.cli import-fta || true

  # Structure & rates
  python -m tolltariff.cli fetch-opendata || true
  python -m tolltariff.cli import-structure || true
  python -m tolltariff.cli fetch-import-fees || true
  python -m tolltariff.cli import-default-rates || true
  # Note: Requires tollavgiftssats.json to be present in raw/ if not fetched elsewhere
  if [[ -n "$TOLL_DUTY_URL" ]]; then
    echo "[bootstrap] Downloading duty rates from $TOLL_DUTY_URL"
    curl -fsSL "$TOLL_DUTY_URL" -o /app/raw/tollavgiftssats.json || echo "[bootstrap] Warning: failed to download tollavgiftssats.json"
  fi
  if [[ -f "/app/raw/tollavgiftssats.json" || -f "/app/data/raw/tollavgiftssats.json" ]]; then
    python -m tolltariff.cli import-duty-rates || true
  else
    echo "[bootstrap] Skipping import-duty-rates (raw/tollavgiftssats.json missing)."
  fi
  echo "[bootstrap] Completed."
else
  echo "[bootstrap] Skipped (TOLLTARIFF_BOOTSTRAP=false)."
fi

# Start API
exec python -m uvicorn tolltariff.api.main:app --host "${HOST:-0.0.0.0}" --port "${PORT:-8000}"
