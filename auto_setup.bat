@echo off
setlocal EnableDelayedExpansion

:: Title and heading
color 03
echo ===============================================
echo            PIX2TEX2SVG AUTO SETUP           
echo ===============================================
echo.
echo After continue, this bat file will:
echo 1. setup anaconda env named `pix2tex2svg`.
echo 2. Update repository with git pull.
echo 3. pip install modules, to the env.
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

:: Current directory
echo.
echo [INFO] Current directory: %cd%


:: Initialize Conda
echo [INFO] Initializing Conda...
CALL "%CONDA_ROOT%\condabin\conda.bat" activate base


:: Check or create environment
echo.
echo [INFO] Checking Conda environment 'pix2tex2svg'...
conda env list | findstr "pix2tex2svg" >nul
if errorlevel 1 (
    echo [INFO] Creating new environment 'pix2tex2svg'...
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


:: Git check
echo.
echo [INFO] Checking for Git...
where git >nul 2>nul
if errorlevel 1 (
    color 0C
    echo [ERROR] Git is not installed or not in PATH.
    pause
    exit /b
) else (
    echo [INFO] Git is available.
    echo [INFO] Updating repository...
    git pull
)


:: Install packages
echo.
echo [INFO] Installing/Updating Python packages...
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
color 0A
endlocal
pause




