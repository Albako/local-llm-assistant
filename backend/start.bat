@echo off
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