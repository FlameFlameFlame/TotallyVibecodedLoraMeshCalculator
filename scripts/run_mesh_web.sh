#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRONTEND_DIR="${ROOT_DIR}/mesh-generator"
BACKEND_DIR="${ROOT_DIR}/mesh-backend"
FRONTEND_DIST_DIR="${FRONTEND_DIR}/dist"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8000}"

cd "${FRONTEND_DIR}"
npm run build

cd "${BACKEND_DIR}"
export FRONTEND_DIST_DIR
exec uv run uvicorn app.main:app --host "${HOST}" --port "${PORT}"
