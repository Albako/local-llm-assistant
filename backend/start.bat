:: Enhanced Windows startup script with GPU support and error handling
@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: Enable error handling
set "ERROR_OCCURRED=0"

:: Get the directory of the current script
SET "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%" || (
    echo ❌ ERROR: Cannot navigate to script directory
    exit /b 1
)

:: Get the parent directory (project root)
FOR %%A IN ("%SCRIPT_DIR%\..") DO SET "PROJECT_ROOT=%%~fA"
echo 📁 Project root: !PROJECT_ROOT!
echo 📁 Backend directory: !SCRIPT_DIR!

:: Initialize variables
SET "USE_DOCKER=true"
SET "GPU_MODE=auto"
SET "COMPOSE_FILES=-f "%PROJECT_ROOT%\docker-compose.yml""

:: Parse command line arguments
:parse_args
IF "%~1"=="" GOTO :args_parsed
IF "%~1"=="--local" SET "USE_DOCKER=false"
IF "%~1"=="--nvidia" SET "GPU_MODE=nvidia"
IF "%~1"=="--amd" SET "GPU_MODE=amd"
IF "%~1"=="--intel" SET "GPU_MODE=intel"
IF "%~1"=="--cpu" SET "GPU_MODE=cpu"
SHIFT
GOTO :parse_args
:args_parsed

IF "%USE_DOCKER%"=="true" (
    echo Running in Docker mode...
    cd /d "%PROJECT_ROOT%" || (
        echo ❌ ERROR: Cannot navigate to project root
        exit /b 1
    )

    :: Check if Docker is running
    echo 🔍 Checking Docker status...
    docker info >nul 2>&1
    if !ERRORLEVEL! NEQ 0 (
        echo ❌ ERROR: Docker is not running!
        echo Please start Docker Desktop and try again.
        exit /b 1
    )
    echo ✅ Docker is running

    :: Check if docker-compose.yml exists
    if not exist "%PROJECT_ROOT%\docker-compose.yml" (
        echo ❌ ERROR: docker-compose.yml not found in %PROJECT_ROOT%
        exit /b 1
    )
    echo ✅ docker-compose.yml found

    :: GPU Detection and Compose File Selection
    IF "%GPU_MODE%"=="auto" (
        echo 🔍 Detecting GPU...

        :: Check for NVIDIA GPU
        nvidia-smi >nul 2>&1
        IF !ERRORLEVEL! EQU 0 (
            echo ✅ NVIDIA GPU detected. Using NVIDIA configuration.
            SET "COMPOSE_FILES=!COMPOSE_FILES! -f "%PROJECT_ROOT%\docker-compose.nvidia.yml""
            SET "GPU_MODE=nvidia"
        ) ELSE (
            echo ℹ️  No NVIDIA GPU detected. Using CPU mode.
            SET "GPU_MODE=cpu"
        )
    ) ELSE (
        IF "%GPU_MODE%"=="nvidia" (
            echo 🎯 Forcing NVIDIA mode.
            SET "COMPOSE_FILES=!COMPOSE_FILES! -f "%PROJECT_ROOT%\docker-compose.nvidia.yml""
        ) ELSE IF "%GPU_MODE%"=="amd" (
            echo 🎯 Forcing AMD mode.
            SET "COMPOSE_FILES=!COMPOSE_FILES! -f "%PROJECT_ROOT%\docker-compose.amd.yml""
        ) ELSE IF "%GPU_MODE%"=="intel" (
            echo 🎯 Forcing Intel mode.
            SET "COMPOSE_FILES=!COMPOSE_FILES! -f "%PROJECT_ROOT%\docker-compose.intel.yml""
        ) ELSE (
            echo 🎯 Using CPU mode.
        )
    )

    echo ====================================================
    echo 🚀 Starting service in mode: !GPU_MODE!
    echo 📄 Compose files: !COMPOSE_FILES!
    echo ====================================================

    :: Check if .env exists, if not create from .env.example
    IF NOT EXIST "%PROJECT_ROOT%\.env" (
        echo ℹ️  .env file not found. Creating from .env.example...
        IF EXIST "%PROJECT_ROOT%\.env.example" (
            copy "%PROJECT_ROOT%\.env.example" "%PROJECT_ROOT%\.env" >nul
            if !ERRORLEVEL! NEQ 0 (
                echo ❌ ERROR: Failed to create .env file
                exit /b 1
            )
            echo ✅ .env file created.
        ) ELSE (
            echo ⚠️  WARNING: .env.example not found! Using default values.
        )
    )

    :: Run Docker Compose with GPU support and error checking
    echo 🔧 Starting Docker containers...
    docker compose --env-file "%PROJECT_ROOT%\.env" !COMPOSE_FILES! up -d
    if !ERRORLEVEL! NEQ 0 (
        echo ❌ ERROR: Failed to start Docker containers
        echo Please check Docker logs for more details.
        exit /b 1
    )

    :: Wait a moment and verify containers are running
    echo 🔍 Verifying containers are running...
    timeout /t 3 /nobreak >nul
    docker compose --env-file "%PROJECT_ROOT%\.env" !COMPOSE_FILES! ps --services --filter "status=running" >nul 2>&1
    if !ERRORLEVEL! NEQ 0 (
        echo ⚠️  WARNING: Some containers may not be running properly
        echo Check container status with: docker compose ps
    )

    echo ✅ Containers started successfully. Access the application at:
    echo   http://localhost:3000
    echo.
    echo To view logs, run:
    echo   docker compose --env-file "%PROJECT_ROOT%\.env" !COMPOSE_FILES! logs -f
    echo.
    echo To stop the containers, run:
    echo   docker compose --env-file "%PROJECT_ROOT%\.env" !COMPOSE_FILES! down
    exit /b 0
)

:: LOCAL DEVELOPMENT MODE
echo ====================================================
echo 🚀 Starting LOCAL DEVELOPMENT MODE
echo ====================================================

:: Check if Python is available
echo 🔍 Checking Python installation...
python --version >nul 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo ❌ ERROR: Python not found!
    echo Please install Python and try again.
    exit /b 1
)
echo ✅ Python is available

:: Check if requirements.txt exists and dependencies are installed
if exist "requirements.txt" (
    echo 🔍 Checking Python dependencies...
    python -c "import uvicorn, open_webui" >nul 2>&1
    if !ERRORLEVEL! NEQ 0 (
        echo ❌ ERROR: Required Python dependencies not installed!
        echo Please run: pip install -r requirements.txt
        exit /b 1
    )
    echo ✅ Python dependencies are available
) else (
    echo ⚠️  WARNING: requirements.txt not found
)

:: Add conditional Playwright browser installation
IF /I "%WEB_LOADER_ENGINE%" == "playwright" (
    IF "%PLAYWRIGHT_WS_URL%" == "" (
        echo 🔍 Installing Playwright browsers...
        playwright install chromium
        if !ERRORLEVEL! NEQ 0 (
            echo ❌ ERROR: Failed to install Playwright browsers
            exit /b 1
        )
        playwright install-deps chromium
        if !ERRORLEVEL! NEQ 0 (
            echo ❌ ERROR: Failed to install Playwright dependencies
            exit /b 1
        )
        echo ✅ Playwright browsers installed
    )

    echo 🔍 Downloading NLTK data...
    python -c "import nltk; nltk.download('punkt_tab')"
    if !ERRORLEVEL! NEQ 0 (
        echo ❌ ERROR: Failed to download NLTK data
        exit /b 1
    )
    echo ✅ NLTK data downloaded
)

SET "KEY_FILE=.webui_secret_key"
IF NOT "%WEBUI_SECRET_KEY_FILE%" == "" (
    SET "KEY_FILE=%WEBUI_SECRET_KEY_FILE%"
)

IF "%PORT%"=="" SET PORT=8080
IF "%HOST%"=="" SET HOST=0.0.0.0
SET "WEBUI_SECRET_KEY=%WEBUI_SECRET_KEY%"
SET "WEBUI_JWT_SECRET_KEY=%WEBUI_JWT_SECRET_KEY%"

:: Check if WEBUI_SECRET_KEY and WEBUI_JWT_SECRET_KEY are not set
IF "%WEBUI_SECRET_KEY%%WEBUI_JWT_SECRET_KEY%" == " " (
    echo 🔍 Loading WEBUI_SECRET_KEY from file, not provided as an environment variable.

    IF NOT EXIST "%KEY_FILE%" (
        echo 🔧 Generating WEBUI_SECRET_KEY
        :: Generate a random value to use as a WEBUI_SECRET_KEY in case the user didn't provide one
        powershell -Command "[System.Web.Security.Membership]::GeneratePassword(24, 0)" > "%KEY_FILE%"
        if !ERRORLEVEL! NEQ 0 (
            echo ❌ ERROR: Failed to generate WEBUI_SECRET_KEY
            exit /b 1
        )
        echo ✅ WEBUI_SECRET_KEY generated
    )

    echo 📄 Loading WEBUI_SECRET_KEY from %KEY_FILE%
    SET /p WEBUI_SECRET_KEY=<%KEY_FILE%
)

:: Final system checks
echo 🔍 Final system check...
IF "%WEBUI_SECRET_KEY%"=="" (
    echo ❌ ERROR: WEBUI_SECRET_KEY not set
    exit /b 1
)

python -c "import open_webui.main" >nul 2>&1
if !ERRORLEVEL! NEQ 0 (
    echo ❌ ERROR: Cannot import open_webui.main module
    echo Please check your Python installation and dependencies
    exit /b 1
)

echo ✅ All checks passed. Starting server...

:: Execute uvicorn with error handling
SET "WEBUI_SECRET_KEY=%WEBUI_SECRET_KEY%"
IF "%UVICORN_WORKERS%"=="" SET UVICORN_WORKERS=1
echo 🚀 Starting Open WebUI server on %HOST%:%PORT%
uvicorn open_webui.main:app --host "%HOST%" --port "%PORT%" --forwarded-allow-ips '*' --workers %UVICORN_WORKERS% --ws auto
if !ERRORLEVEL! NEQ 0 (
    echo ❌ ERROR: Failed to start Open WebUI server
    exit /b 1
)
:: For ssl user uvicorn open_webui.main:app --host "%HOST%" --port "%PORT%" --forwarded-allow-ips '*' --ssl-keyfile "key.pem" --ssl-certfile "cert.pem" --ws auto
ECHO.
ECHO ------------------------------------------------------------------------------------
ECHO Skrypt start.bat zakonczyl dzialanie.
pause
