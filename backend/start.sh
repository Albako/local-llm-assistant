#!/bin/bash

# Sprawdzenie czy istnieje plik .env
if [ ! -f .env]; then
    echo "Plik .env nie istnieje. Tworzenie pliku na podstawie szablonu .env.example..."
    if [ -f .env.example ]; then
        cp .env.example .env
        echo "Plik .env zostal utworzony."
    else
        echo "UWAGA: Nie odnaleziono pliku .env.example! Uzyte zostana domyslne wartosci."
    fi
fi

# Domyślna konfiguracja to plik bazowy (CPU)
COMPOSE_FILES="-f docker-compose.yml"
MODE="CPU"

# --- Zunifikowana logika wyboru trybu ---

# Sprawdź, czy użytkownik podał flagę wyboru
if [[ "$1" == "--nvidia" ]]; then
    echo "Wymuszono tryb NVIDIA."
    COMPOSE_FILES="-f docker-compose.yml -f docker-compose.nvidia.yml"
    MODE="NVIDIA"
elif [[ "$1" == "--amd" ]]; then
    echo "Wymuszono tryb AMD."
    COMPOSE_FILES="-f docker-compose.yml -f docker-compose.amd.yml"
    MODE="AMD"
elif [[ "$1" == "--intel" ]]; then
    echo "Wymuszono tryb INTEL."
    COMPOSE_FILES="-f docker-compose.yml -f docker-compose.intel.yml"
    MODE="INTEL"
elif [[ "$1" == "--cpu" ]]; then
    echo "Wymuszono tryb CPU."
    # Nic nie trzeba dodawać, plik bazowy jest już wybrany
else
    # Jeśli nie podano flagi, uruchom auto-detekcję
    echo "Trwa automatyczne wykrywanie GPU"
    if command -v nvidia-smi &> /dev/null; then
        echo "Wykryto GPU NVIDIA. Używam konfiguracji NVIDIA."
        COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.nvidia.yml"
        MODE="NVIDIA"
    elif [ -e /dev/kfd ]; then
        echo "Wykryto GPU AMD. Używam konfiguracji AMD."
        COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.amd.yml"
        MODE="AMD"
    elif lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq "intel"; then
        echo "Wykryto GPU INTEL. Używam konfiguracji INTEL."
        COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.intel.yml"
        MODE="INTEL"
    else
        echo "Nie wykryto kompatybilnego GPU. Używam konfiguracji CPU."
    fi
fi

# --- Uruchomienie docker-compose z wybraną konfiguracją ---
echo "____________________________________________________"
echo "Uruchamianie serwisu w trybie: $MODE"
echo "____________________________________________________"

# Przekaż argumenty (np. -d, --build) do docker-compose
# Jeśli podano flagę trybu, pomiń ją ($@:2), w przeciwnym razie przekaż wszystko ($@)
if [[ "$1" == --* ]]; then
    docker compose $COMPOSE_FILES up -d "${@:2}"
else
    docker compose $COMPOSE_FILES up -d "$@"
fi

#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR" || exit

# Add conditional Playwright browser installation
if [[ "${WEB_LOADER_ENGINE,,}" == "playwright" ]]; then
    if [[ -z "${PLAYWRIGHT_WS_URL}" ]]; then
        echo "Installing Playwright browsers..."
        playwright install chromium
        playwright install-deps chromium
    fi

    python -c "import nltk; nltk.download('punkt_tab')"
fi

if [ -n "${WEBUI_SECRET_KEY_FILE}" ]; then
    KEY_FILE="${WEBUI_SECRET_KEY_FILE}"
else
    KEY_FILE=".webui_secret_key"
fi

PORT="${PORT:-8080}"
HOST="${HOST:-0.0.0.0}"
if test "$WEBUI_SECRET_KEY $WEBUI_JWT_SECRET_KEY" = " "; then
  echo "Loading WEBUI_SECRET_KEY from file, not provided as an environment variable."

  if ! [ -e "$KEY_FILE" ]; then
    echo "Generating WEBUI_SECRET_KEY"
    # Generate a random value to use as a WEBUI_SECRET_KEY in case the user didn't provide one.
    echo $(head -c 12 /dev/random | base64) > "$KEY_FILE"
  fi

  echo "Loading WEBUI_SECRET_KEY from $KEY_FILE"
  WEBUI_SECRET_KEY=$(cat "$KEY_FILE")
fi

if [[ "${USE_OLLAMA_DOCKER,,}" == "true" ]]; then
    echo "USE_OLLAMA is set to true, starting ollama serve."
    ollama serve &
fi

if [[ "${USE_CUDA_DOCKER,,}" == "true" ]]; then
  echo "CUDA is enabled, appending LD_LIBRARY_PATH to include torch/cudnn & cublas libraries."
  export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib/python3.11/site-packages/torch/lib:/usr/local/lib/python3.11/site-packages/nvidia/cudnn/lib"
fi

# Check if SPACE_ID is set, if so, configure for space
if [ -n "$SPACE_ID" ]; then
  echo "Configuring for HuggingFace Space deployment"

 if [ -n "$ADMIN_USER_EMAIL" ] && [ -n "$ADMIN_USER_PASSWORD" ]; then
    echo "Admin user configured, creating"
    WEBUI_SECRET_KEY="$WEBUI_SECRET_KEY" uvicorn open_webui.main:app --host "$HOST" --port "$PORT" --forwarded-allow-ips '*' &
    webui_pid=$!
    echo "Waiting for webui to start..."
    while ! curl -s http://localhost:8080/health > /dev/null; do
      sleep 1
    done
    echo "Creating admin user..."
    curl \
      -X POST "http://localhost:8080/api/v1/auths/signup" \
      -H "accept: application/json" \
      -H "Content-Type: application/json" \
      -d "{ \"email\": \"${ADMIN_USER_EMAIL}\", \"password\": \"${ADMIN_USER_PASSWORD}\", \"name\": \"Admin\" }"
    echo "Shutting down webui..."
    kill $webui_pid
  fi

  export WEBUI_URL=${SPACE_HOST}
fi

PYTHON_CMD=$(command -v python3 || command -v python)

WEBUI_SECRET_KEY="$WEBUI_SECRET_KEY" exec "$PYTHON_CMD" -m uvicorn open_webui.main:app --host "$HOST" --port "$PORT" --forwarded-allow-ips '*' --workers "${UVICORN_WORKERS:-1}"
