@echo off
echo ====== ENHANCED START.BAT WITH GPU SUPPORT ======
echo.
echo start.bat teraz obsługuje:
echo.
echo 1. Automatyczne wykrywanie NVIDIA GPU:
echo    .\start.bat
echo.
echo 2. Wymuszenie określonego trybu GPU:
echo    .\start.bat --nvidia
echo    .\start.bat --amd
echo    .\start.bat --intel
echo    .\start.bat --cpu
echo.
echo 3. Tryb lokalny (bez Docker):
echo    .\start.bat --local
echo.
echo ====== WYMAGANIA DLA GPU SUPPORT ======
echo.
echo - Docker Desktop z GPU support
echo - NVIDIA: nvidia-smi w PATH + CUDA drivers
echo - AMD/Intel: eksperymentalne (może wymagać WSL2)
echo.
echo ====== TEST NVIDIA GPU ======
echo.
nvidia-smi >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo ✅ NVIDIA GPU detected - start.bat will use GPU acceleration
    nvidia-smi --query-gpu=name --format=csv,noheader
) else (
    echo ❌ NVIDIA GPU not detected - start.bat will use CPU mode
    echo    Install NVIDIA drivers and ensure nvidia-smi is in PATH
)
echo.
echo ====== DOCKER VERSION ======
echo.
docker --version
docker compose version
echo.
echo ====== READY TO USE ======
echo.
echo Możesz teraz używać start.bat z pełną obsługą GPU!
echo.
pause
