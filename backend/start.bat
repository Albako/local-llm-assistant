:: This method is not recommended, and we recommend you use the `start.sh` file with WSL instead.
@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: Get the directory of the current script
SET "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%" || exit /b

:: Get the parent directory (project root)
FOR %%A IN ("%SCRIPT_DIR%\..") DO SET "PROJECT_ROOT=%%~fA"

:: Check if we should run in Docker mode or local development mode
:: If no --local flag is provided, we assume Docker mode and use Docker Compose
SET "USE_DOCKER=true"
:parse_args
IF "%~1"=="" GOTO :args_parsed
IF "%~1"=="--local" SET "USE_DOCKER=false"
SHIFT
GOTO :parse_args
:args_parsed

IF "%USE_DOCKER%"=="true" (
    echo Running in Docker mode...
    cd /d "%PROJECT_ROOT%" || exit /b
    
    :: Check if .env exists, if not create from .env.example
    IF NOT EXIST "%PROJECT_ROOT%\.env" (
        echo .env file not found. Creating from .env.example...
        IF EXIST "%PROJECT_ROOT%\.env.example" (
            copy "%PROJECT_ROOT%\.env.example" "%PROJECT_ROOT%\.env"
            echo .env file created.
        ) ELSE (
            echo WARNING: .env.example not found! Using default values.
        )
    )
    
    :: Run Docker Compose
    docker compose --env-file "%PROJECT_ROOT%\.env" up -d
    
    echo Containers started successfully. Access the application at:
    echo   http://localhost:3000
    echo.
    echo To view logs, run:
    echo   docker compose logs -f
    echo.
    echo To stop the containers, run:
    echo   docker compose down
    exit /b 0
)

:: Add conditional Playwright browser installation
IF /I "%WEB_LOADER_ENGINE%" == "playwright" (
    IF "%PLAYWRIGHT_WS_URL%" == "" (
        echo Installing Playwright browsers...
        playwright install chromium
        playwright install-deps chromium
    )

    python -c "import nltk; nltk.download('punkt_tab')"
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
    echo Loading WEBUI_SECRET_KEY from file, not provided as an environment variable.

    IF NOT EXIST "%KEY_FILE%" (
        echo Generating WEBUI_SECRET_KEY
        :: Generate a random value to use as a WEBUI_SECRET_KEY in case the user didn't provide one
        powershell -Command "[System.Web.Security.Membership]::GeneratePassword(24, 0)" > "%KEY_FILE%"
        echo WEBUI_SECRET_KEY generated
    )

    echo Loading WEBUI_SECRET_KEY from %KEY_FILE%
    SET /p WEBUI_SECRET_KEY=<%KEY_FILE%
)

:: Execute uvicorn
SET "WEBUI_SECRET_KEY=%WEBUI_SECRET_KEY%"
IF "%UVICORN_WORKERS%"=="" SET UVICORN_WORKERS=1
uvicorn open_webui.main:app --host "%HOST%" --port "%PORT%" --forwarded-allow-ips '*' --workers %UVICORN_WORKERS% --ws auto
:: For ssl user uvicorn open_webui.main:app --host "%HOST%" --port "%PORT%" --forwarded-allow-ips '*' --ssl-keyfile "key.pem" --ssl-certfile "cert.pem" --ws auto
ECHO.
ECHO ------------------------------------------------------------------------------------
ECHO Skrypt start.bat zakonczyl dzialanie.
pause