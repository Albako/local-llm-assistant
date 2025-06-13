#!/usr/bin/env bash
# start.sh – uruchamia lokalny serwer FastAPI

set -e
# Źródło zmiennych środowiskowych (jeśli jest plik .env)
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

uvicorn app.main:app --reload --host $API_HOST --port $API_PORT
