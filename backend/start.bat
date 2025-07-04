:: This method is not recommended, and we recommend you use the `start.sh` file with WSL instead.
@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: Get the directory of the current script
SET "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%" || exit /b

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
IF "%HOST%"=="" SET HOST=0.0.0.0c
SET "WEBUI_SECRET_KEY=%WEBUI_SECRET_KEY%"
SET "WEBUI_JWT_SECRET_KEY=%WEBUI_JWT_SECRET_KEY%"

:: Check if WEBUI_SECRET_KEY and WEBUI_JWT_SECRET_KEY are not set
IF "%WEBUI_SECRET_KEY%%WEBUI_JWT_SECRET_KEY%" == " " (
    echo Loading WEBUI_SECRET_KEY from file, not provided as an environment variable.

    IF NOT EXIST "%KEY_FILE%" (
        echo Generating WEBUI_SECRET_KEY
        :: Generate a random value to use as a WEBUI_SECRET_KEY in case the user didn't provide one
        SET /p WEBUI_SECRET_KEY=<nul
        FOR /L %%i IN (1,1,12) DO SET /p WEBUI_SECRET_KEY=<!random!>>%KEY_FILE%
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
ECHO Sprawdzanie srodowiska Windows dla projektu...
ECHO ===================================================================

REM --- Sprawdzanie i tworzenie pliku .env ---
if not exist .env (
    echo Plik .env nie istnieje. Tworze go na podstawie szablonu .env.example...
    if exist .env.example (
        copy .env.example .env > nul
        echo Plik .env zostal utworzony.
    ) else (
        echo OSTRZEZENIE: Nie znaleziono pliku-szablonu .env.example!
    )
)
ECHO.

REM --- Krok 1: Sprawdzanie WSL ---
wsl.exe -l -v > nul 2> nul
if %errorlevel% neq 0 GOTO :ERROR_WSL
ECHO [OK] Wykryto Windows Subsystem for Linux (WSL 2).
GOTO :CHECK_DOCKER

:ERROR_WSL
ECHO.
ECHO [BLAD] Windows Subsystem for Linux (WSL 2) nie jest zainstalowany.
ECHO Jest on wymagany do uruchomienia projektu.
ECHO.
ECHO Jak to naprawic?
ECHO 1. Otworz PowerShell jako Administrator i wpisz: wsl --install
ECHO 2. Uruchom ponownie komputer i sprobuj jeszcze raz.
ECHO.
GOTO :END

:CHECK_DOCKER
REM --- Krok 2: Sprawdzanie Docker ---
where docker > nul 2> nul
if %errorlevel% neq 0 GOTO :ERROR_DOCKER
ECHO [OK] Wykryto instalacje Docker.
GOTO :RUN_PROJECT

:ERROR_DOCKER
ECHO.
ECHO [BLAD] Komenda 'docker' nie zostala znaleziona.
ECHO Upewnij sie, ze masz zainstalowany Docker Desktop for Windows.
ECHO Pobierz go ze strony: https://www.docker.com/products/docker-desktop/
ECHO.
GOTO :END

:RUN_PROJECT
REM --- Krok 3: Uruchomienie projektu ---
ECHO.
ECHO Srodowisko gotowe. Przekazuje sterowanie do skryptu start.sh wewnatrz WSL...
ECHO ------------------------------------------------------------------------------------
ECHO.
wsl.exe ./start.sh %*

:END
ECHO.
ECHO ------------------------------------------------------------------------------------
ECHO Skrypt start.bat zakonczyl dzialanie.
pause