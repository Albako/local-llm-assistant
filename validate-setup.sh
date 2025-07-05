#!/bin/bash

# Project Setup Validation Script
echo "========================================="
echo "Open WebUI Project Setup Validation"
echo "========================================="
echo

# Check if we're in the correct directory
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ Error: docker-compose.yml not found. Please run this script from the project root."
    exit 1
fi

echo "✅ Found docker-compose.yml"

# Check for .env file
if [ ! -f ".env" ]; then
    echo "⚠️  Warning: .env file not found. Creating from .env.example..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo "✅ Created .env from .env.example"
    else
        echo "❌ Error: .env.example not found!"
        exit 1
    fi
else
    echo "✅ Found .env file"
fi

# Check for required environment variables
echo
echo "Checking environment variables..."
source .env 2>/dev/null || echo "⚠️  Warning: Could not source .env file"

if [ -z "$OLLAMA_MODELS" ]; then
    echo "⚠️  Warning: OLLAMA_MODELS is not set in .env"
else
    echo "✅ OLLAMA_MODELS is set: $OLLAMA_MODELS"
fi

if [ -z "$OLLAMA_BASE_URL" ]; then
    echo "⚠️  Warning: OLLAMA_BASE_URL is not set in .env"
else
    echo "✅ OLLAMA_BASE_URL is set: $OLLAMA_BASE_URL"
fi

# Check Docker
echo
echo "Checking Docker..."
if command -v docker &> /dev/null; then
    echo "✅ Docker is installed"
    if docker info &> /dev/null; then
        echo "✅ Docker daemon is running"
    else
        echo "❌ Docker daemon is not running"
        exit 1
    fi
else
    echo "❌ Docker is not installed"
    exit 1
fi

# Check Docker Compose
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
    echo "✅ Docker Compose is available"
else
    echo "❌ Docker Compose is not available"
    exit 1
fi

# Check shell script permissions
echo
echo "Checking shell script permissions..."
SCRIPT_ERRORS=0
for script in $(find . -name "*.sh" -type f); do
    if [ -x "$script" ]; then
        echo "✅ $script is executable"
    else
        echo "❌ $script is not executable"
        SCRIPT_ERRORS=1
    fi
done

if [ $SCRIPT_ERRORS -eq 1 ]; then
    echo
    echo "Fix script permissions by running:"
    echo "  chmod +x *.sh"
    echo "  ./fix-permissions.sh"
fi

# Check required files
echo
echo "Checking required files..."
REQUIRED_FILES=(
    "backend/ui_start.sh"
    "backend/launch.sh"
    "backend/start.bat"
    "backend/requirements.txt"
    "backend/ollama_backend/Dockerfile"
    "backend/ollama_backend/entrypoint.sh"
    "backend/ollama_backend/Modelfile"
    "package.json"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file is missing"
    fi
done

# Check ports
echo
echo "Checking if ports are available..."
if ss -tuln | grep -q ":8080"; then
    echo "⚠️  Warning: Port 8080 is already in use"
else
    echo "✅ Port 8080 is available"
fi

echo "Checking if ports are available..."
if ss -tuln | grep -q ":3000"; then
    echo "⚠️  Warning: Port 3000 is already in use"
else
    echo "✅ Port 3000 is available"
fi

if ss -tuln | grep -q ":11434"; then
    echo "⚠️  Warning: Port 11434 is already in use"
else
    echo "✅ Port 11434 is available"
fi

echo
echo "========================================="
echo "Validation Complete"
echo "========================================="
echo
echo "If all checks passed, you can run:"
echo "  ./backend/launch.sh        # Linux/WSL"
echo "  ./backend/start.bat        # Windows"
echo
