#!/bin/bash
set -e  # Exit on any error

# Function to handle errors
handle_error() {
    local exit_code=$?
    echo "❌ ERROR: Command failed with exit code $exit_code"
    echo "❌ Setup incomplete. Please check the error above."
    exit $exit_code
}

# Set error trap
trap 'handle_error' ERR

# Always resolve PROJECT_ROOT as the parent of the backend directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$SCRIPT_DIR" || exit 1

echo "📁 Project root: $PROJECT_ROOT"
echo "📁 Backend directory: $SCRIPT_DIR"

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

    # Check if Docker is running
    echo "🔍 Checking Docker status..."
    if ! docker info >/dev/null 2>&1; then
        echo "❌ ERROR: Docker is not running!"
        echo "Please start Docker Desktop and try again."
        exit 1
    fi
    echo "✅ Docker is running"

    # Check if docker compose is available
    if ! command -v docker >/dev/null 2>&1; then
        echo "❌ ERROR: Docker command not found!"
        echo "Please install Docker and try again."
        exit 1
    fi

    # Verify compose files exist
    if [[ ! -f "$PROJECT_ROOT/docker-compose.yml" ]]; then
        echo "❌ ERROR: docker-compose.yml not found in $PROJECT_ROOT"
        exit 1
    fi

    # Run docker compose and check for errors
    echo "🚀 Starting Docker containers..."
    if [[ "$1" == --* && "$1" != "--local" ]]; then
        if ! docker compose --env-file "$PROJECT_ROOT/.env" $COMPOSE_FILES up -d "${@:2}"; then
            echo "❌ ERROR: Failed to start Docker containers"
            echo "Check Docker logs for more details."
            exit 1
        fi
    else
        if ! docker compose --env-file "$PROJECT_ROOT/.env" $COMPOSE_FILES up -d "$@"; then
            echo "❌ ERROR: Failed to start Docker containers"
            echo "Check Docker logs for more details."
            exit 1
        fi
    fi

    # Verify containers are actually running
    echo "🔍 Verifying containers are running..."
    sleep 3
    if ! docker compose --env-file "$PROJECT_ROOT/.env" $COMPOSE_FILES ps --services --filter "status=running" >/dev/null 2>&1; then
        echo "❌ WARNING: Some containers may not be running properly"
        echo "Check container status with: docker compose ps"
    fi

    echo "✅ Containers started successfully. Access the application at:"
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

# Check if Python is available
echo "🔍 Checking Python installation..."
PYTHON_CMD=$(command -v python3 || command -v python || echo "")
if [[ -z "$PYTHON_CMD" ]]; then
    echo "❌ ERROR: Python not found!"
    echo "Please install Python and try again."
    exit 1
fi
echo "✅ Python found: $PYTHON_CMD"

# Check if requirements.txt exists and dependencies are installed
if [[ -f "requirements.txt" ]]; then
    echo "🔍 Checking Python dependencies..."
    if ! $PYTHON_CMD -c "import uvicorn, open_webui" >/dev/null 2>&1; then
        echo "❌ ERROR: Required Python dependencies not installed!"
        echo "Please run: pip install -r requirements.txt"
        exit 1
    fi
    echo "✅ Python dependencies available"
else
    echo "⚠️  WARNING: requirements.txt not found"
fi

echo ""

# Add conditional Playwright browser installation
if [[ "${WEB_LOADER_ENGINE,,}" == "playwright" ]]; then
    if [[ -z "${PLAYWRIGHT_WS_URL}" ]]; then
        echo "🔍 Installing Playwright browsers..."
        if ! playwright install chromium; then
            echo "❌ ERROR: Failed to install Playwright browsers"
            exit 1
        fi
        if ! playwright install-deps chromium; then
            echo "❌ ERROR: Failed to install Playwright dependencies"
            exit 1
        fi
        echo "✅ Playwright browsers installed"
    fi

    echo "🔍 Downloading NLTK data..."
    if ! python -c "import nltk; nltk.download('punkt_tab')"; then
        echo "❌ ERROR: Failed to download NLTK data"
        exit 1
    fi
    echo "✅ NLTK data downloaded"
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
    echo "🔍 Configuring for HuggingFace Space deployment"

    if [ -n "$ADMIN_USER_EMAIL" ] && [ -n "$ADMIN_USER_PASSWORD" ]; then
        echo "Admin user configured, creating"
        if ! WEBUI_SECRET_KEY="$WEBUI_SECRET_KEY" uvicorn open_webui.main:app --host "$HOST" --port "$PORT" --forwarded-allow-ips '*' &; then
            echo "❌ ERROR: Failed to start webui for admin user creation"
            exit 1
        fi
        webui_pid=$!
        
        echo "Waiting for webui to start..."
        local retries=0
        while ! curl -s http://localhost:8080/health > /dev/null; do
            sleep 1
            retries=$((retries + 1))
            if [ $retries -gt 30 ]; then
                echo "❌ ERROR: WebUI failed to start within 30 seconds"
                kill $webui_pid 2>/dev/null
                exit 1
            fi
        done
        
        echo "Creating admin user..."
        if ! curl \
            -X POST "http://localhost:8080/api/v1/auths/signup" \
            -H "accept: application/json" \
            -H "Content-Type: application/json" \
            -d "{ \"email\": \"${ADMIN_USER_EMAIL}\", \"password\": \"${ADMIN_USER_PASSWORD}\", \"name\": \"Admin\" }"; then
            echo "❌ ERROR: Failed to create admin user"
            kill $webui_pid 2>/dev/null
            exit 1
        fi
        
        echo "Shutting down webui..."
        kill $webui_pid
    fi

    export WEBUI_URL=${SPACE_HOST}
fi

echo "🚀 Starting Open WebUI server on $HOST:$PORT"
echo "🔍 Final system check..."

# Final verification before starting
if [[ -z "$WEBUI_SECRET_KEY" ]]; then
    echo "❌ ERROR: WEBUI_SECRET_KEY not set"
    exit 1
fi

if ! $PYTHON_CMD -c "import open_webui.main" >/dev/null 2>&1; then
    echo "❌ ERROR: Cannot import open_webui.main module"
    echo "Please check your Python installation and dependencies"
    exit 1
fi

echo "✅ All checks passed. Starting server..."
if ! WEBUI_SECRET_KEY="$WEBUI_SECRET_KEY" exec "$PYTHON_CMD" -m uvicorn open_webui.main:app --host "$HOST" --port "$PORT" --forwarded-allow-ips '*' --workers "${UVICORN_WORKERS:-1}"; then
    echo "❌ ERROR: Failed to start Open WebUI server"
    exit 1
fi
