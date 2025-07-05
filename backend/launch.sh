#!/bin/bash

# Always resolve PROJECT_ROOT as the parent of the backend directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$SCRIPT_DIR" || exit 1

# Ensure .env exists in the project root
if [ ! -f "$PROJECT_ROOT/.env" ]; then
    echo "Plik .env nie istnieje w katalogu głównym. Tworzenie pliku na podstawie szablonu .env.example..."
    if [ -f "$PROJECT_ROOT/.env.example" ]; then
        cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env"
        echo "Plik .env zostal utworzony w katalogu głównym."
    else
        echo "UWAGA: Nie odnaleziono pliku .env.example w katalogu głównym! Uzyte zostana domyslne wartosci."
    fi
fi

# Export all variables from .env so they are available to docker compose
if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
fi

COMPOSE_FILES="-f $PROJECT_ROOT/docker-compose.yml"
MODE="CPU"

if [[ "$1" == "--nvidia" ]]; then
    echo "Wymuszono tryb NVIDIA."
    COMPOSE_FILES="-f $PROJECT_ROOT/docker-compose.yml -f $PROJECT_ROOT/docker-compose.nvidia.yml"
    MODE="NVIDIA"
elif [[ "$1" == "--amd" ]]; then
    echo "Wymuszono tryb AMD."
    COMPOSE_FILES="-f $PROJECT_ROOT/docker-compose.yml -f $PROJECT_ROOT/docker-compose.amd.yml"
    MODE="AMD"
elif [[ "$1" == "--intel" ]]; then
    echo "Wymuszono tryb INTEL."
    COMPOSE_FILES="-f $PROJECT_ROOT/docker-compose.yml -f $PROJECT_ROOT/docker-compose.intel.yml"
    MODE="INTEL"
elif [[ "$1" == "--cpu" ]]; then
    echo "Wymuszono tryb CPU."
elif [[ "$1" == "--local" ]]; then
    echo "Uruchamianie w trybie lokalnym (bez Docker)..."
    # Jump directly to local development mode
    MODE="LOCAL"
else
    echo "Trwa automatyczne wykrywanie GPU"
    if command -v nvidia-smi &> /dev/null; then
        echo "Wykryto GPU NVIDIA. Używam konfiguracji NVIDIA."
        COMPOSE_FILES="$COMPOSE_FILES -f $PROJECT_ROOT/docker-compose.nvidia.yml"
        MODE="NVIDIA"
    elif [ -e /dev/kfd ]; then
        echo "Wykryto GPU AMD. Używam konfiguracji AMD."
        COMPOSE_FILES="$COMPOSE_FILES -f $PROJECT_ROOT/docker-compose.amd.yml"
        MODE="AMD"
    elif command -v lspci &> /dev/null && lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq "intel"; then
        echo "Wykryto GPU INTEL. Używam konfiguracji INTEL."
        COMPOSE_FILES="$COMPOSE_FILES -f $PROJECT_ROOT/docker-compose.intel.yml"
        MODE="INTEL"
    else
        echo "Nie wykryto kompatybilnego GPU. Używam konfiguracji CPU."
    fi
fi

# Handle Docker mode
if [[ "$MODE" != "LOCAL" ]]; then
    echo "____________________________________________________"
    echo "Uruchamianie serwisu w trybie: $MODE"
    echo "____________________________________________________"

    # Always use the project root .env file for docker compose
    if [[ "$1" == --* && "$1" != "--local" ]]; then
        docker compose --env-file "$PROJECT_ROOT/.env" $COMPOSE_FILES up -d "${@:2}"
    else
        docker compose --env-file "$PROJECT_ROOT/.env" $COMPOSE_FILES up -d "$@"
    fi

    echo "Containers started successfully. Access the application at:"
    echo "  http://localhost:${OPEN_WEBUI_PORT:-3000}"
    echo ""
    echo "To view logs, run:"
    echo "  docker compose --env-file \"$PROJECT_ROOT/.env\" $COMPOSE_FILES logs -f"
    echo ""
    echo "To stop the containers, run:"
    echo "  docker compose --env-file \"$PROJECT_ROOT/.env\" $COMPOSE_FILES down"
    exit 0
fi

# LOCAL DEVELOPMENT MODE (--local flag was provided)
echo "____________________________________________________"
echo "Uruchamianie serwisu w trybie: LOCAL DEVELOPMENT"
echo "____________________________________________________"

echo "Running in LOCAL DEVELOPMENT MODE"
echo "This requires Python dependencies to be installed locally."
echo "Make sure you have run: pip install -r requirements.txt"
echo ""

# Add conditional Playwright browser installation
if [[ "${WEB_LOADER_ENGINE,,}" == "playwright" ]]; then
    if [[ -z "${PLAYWRIGHT_WS_URL}" ]]; then
        echo "Installing Playwright browsers..."
        playwright install chromium
        playwright install-deps chromium
    fi

    python -c "import nltk; nltk.download('punkt_tab')"
fi

# Handle secret key for local development
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

echo "Starting Open WebUI server on $HOST:$PORT"
WEBUI_SECRET_KEY="$WEBUI_SECRET_KEY" exec "$PYTHON_CMD" -m uvicorn open_webui.main:app --host "$HOST" --port "$PORT" --forwarded-allow-ips '*' --workers "${UVICORN_WORKERS:-1}"
