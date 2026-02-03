#!/usr/bin/env bash
set -euo pipefail

# Ensure expected dirs exist
mkdir -p /app/data /app/raw

BOOTSTRAP=${TOLLTARIFF_BOOTSTRAP:-true}
TOLL_DUTY_URL=${TOLLTARIFF_DUTY_URL:-}

if [[ "$BOOTSTRAP" == "true" ]]; then
  (
    set -e
    echo "[bootstrap] Running data fetch/import in background..."
    # Fetch catalogs
    echo "[bootstrap] Step 1: fetch-landgroups"
    python -m tolltariff.cli fetch-landgroups || true
    echo "[bootstrap] Step 1b: import-landgroups"
    python -m tolltariff.cli import-landgroups || true
    echo "[bootstrap] Step 2: fetch-fta"
    python -m tolltariff.cli fetch-fta || true
    echo "[bootstrap] Step 2b: import-fta"
    python -m tolltariff.cli import-fta || true

    # Structure & rates
    echo "[bootstrap] Step 3: fetch structure"
    python -m tolltariff.cli fetch-opendata || true
    echo "[bootstrap] Step 3b: import structure"
    python -m tolltariff.cli import-structure || true
    echo "[bootstrap] Step 4: fetch import fees (innfoerselsavgift)"
    python -m tolltariff.cli fetch-import-fees || true
    echo "[bootstrap] Step 4b: import default rates (MV %)"
    python -m tolltariff.cli import-default-rates || true
    # Duty rates
    if [[ -n "$TOLL_DUTY_URL" ]]; then
      echo "[bootstrap] Step 5: download duty rates from $TOLL_DUTY_URL"
      curl -fsSL "$TOLL_DUTY_URL" -o /app/raw/tollavgiftssats.json || echo "[bootstrap] Warning: failed to download tollavgiftssats.json"
    fi
    if [[ -f "/app/raw/tollavgiftssats.json" || -f "/app/data/raw/tollavgiftssats.json" ]]; then
      echo "[bootstrap] Step 5b: import duty rates (this may take a few minutes)"
      python -m tolltariff.cli import-duty-rates || true
    else
      echo "[bootstrap] Skipping import-duty-rates (raw/tollavgiftssats.json missing)."
    fi
    echo "[bootstrap] Completed."
  ) &
else
  echo "[bootstrap] Skipped (TOLLTARIFF_BOOTSTRAP=false)."
fi

# Start API (bind to PORT provided by platform)
exec python -m uvicorn tolltariff.api.main:app --host "${HOST:-0.0.0.0}" --port "${PORT:-8000}"
