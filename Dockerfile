FROM python:3.12-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# System deps (git, curl for data fetches; tzdata; ca-certificates)
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl ca-certificates tzdata git \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/
RUN pip install --upgrade pip && pip install -r requirements.txt

COPY . /app

# Default envs
ENV PORT=8000 \
    HOST=0.0.0.0 \
    DATABASE_URL=sqlite:///data.db \
    TOLLTARIFF_BOOTSTRAP=true

EXPOSE 8000

RUN chmod +x docker/start.sh || true

CMD ["/bin/bash", "docker/start.sh"]
