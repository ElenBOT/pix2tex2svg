@echo off
setlocal EnableDelayedExpansion

:: Title and heading
color 03
echo ===============================================
echo            PIX2TEX2SVG AUTO SETUP           
echo ===============================================
echo.
echo This script will:
echo 1. Setup anaconda env named `pix2tex2svg`.
echo 2. Update repository with latest code.
echo 3. Install required Python packages.
echo.
pause
echo.
color 07

:: Conda detection
set "CONDA_ANACONDA=%USERPROFILE%\anaconda3"
set "CONDA_MINICONDA=%USERPROFILE%\miniconda3"
set "CONDA_PROGDATA=C:\ProgramData\Anaconda3"
set "CONDA_ROOT="

if exist "%CONDA_ANACONDA%" (
    set "CONDA_ROOT=%CONDA_ANACONDA%"
) else if exist "%CONDA_MINICONDA%" (
    set "CONDA_ROOT=%CONDA_MINICONDA%"
) else if exist "%CONDA_PROGDATA%" (
    set "CONDA_ROOT=%CONDA_PROGDATA%"
)

if defined CONDA_ROOT (
    echo [INFO] Found Conda at: %CONDA_ROOT%
) else (
    color 0C
    echo [ERROR] Conda installation not found!
    pause
    exit /b
)

:: Git Update (Step 1)
echo.
echo [INFO] Updating repository...
if exist .git (
    git pull
) else (
    echo [WARNING] .git not found, skipping update.
)

:: Initialize Conda (Step 2)
echo.
echo [INFO] Initializing Conda...
CALL "%CONDA_ROOT%\condabin\conda.bat" activate base

:: Check or create environment (Step 3)
echo.
echo [INFO] Checking Conda environment 'pix2tex2svg'...
conda env list | findstr "pix2tex2svg" >nul
if errorlevel 1 (
    echo [INFO] Creating new environment 'pix2tex2svg' (Python 3.11)...
    CALL conda create -y -n pix2tex2svg python=3.11
    if errorlevel 1 (
        color 0C
        echo [ERROR] Failed to create environment!
        pause
        exit /b
    )
) else (
    echo [INFO] Environment 'pix2tex2svg' already exists.
)

:: Activate environment
color 07
echo [INFO] Activating 'pix2tex2svg'...
CALL conda activate pix2tex2svg
if errorlevel 1 (
    color 0C
    echo [ERROR] Failed to activate environment!
    pause
    exit /b
)

:: Install packages (Step 4)
echo.
echo [INFO] Installing/Updating Python packages...
:: Note: cryptography added for HTTPS support
pip install "pix2tex[api]" fastapi uvicorn pillow python-multipart cryptography
if errorlevel 1 (
    color 0E
    echo [WARNING] Some packages may have failed to install.
) else (
    echo [INFO] Packages updated successfully.
)

echo.
echo ==================================================
echo           SETUP COMPLETE - READY TO USE           
echo ==================================================
echo.
echo To start, run start_server.bat
echo.
color 0A
endlocal
pause



