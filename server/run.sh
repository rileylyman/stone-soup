#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

if [ ! -d .venv ]; then
    echo "Virtual environment not found. Run setup.sh first."
    exit 1
fi

source .venv/bin/activate

export PYTHONUNBUFFERED=1
uvicorn main:app --reload --host 0.0.0.0 --port "${PORT:-8000}"
