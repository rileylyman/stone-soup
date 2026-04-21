#!/usr/bin/env bash
set -e

PYTHON=${PYTHON:-python3.10}

if ! command -v "$PYTHON" &>/dev/null; then
    echo "Error: $PYTHON not found. Install Python 3.10 or set PYTHON=path/to/python3.10"
    exit 1
fi

$PYTHON -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo ""
echo "Setup complete. To start the server:"
echo "  source .venv/bin/activate"
echo "  uvicorn main:app --reload"
