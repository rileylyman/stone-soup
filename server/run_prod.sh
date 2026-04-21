#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

if [ ! -d .venv ]; then
    echo "Virtual environment not found. Run setup.sh first."
    exit 1
fi

source .venv/bin/activate

WORKERS=${WORKERS:-4}
HOST=${HOST:-0.0.0.0}
PORT=${PORT:-8000}

exec gunicorn main:app \
    -w "$WORKERS" \
    -k uvicorn.workers.UvicornWorker \
    --bind "$HOST:$PORT"
