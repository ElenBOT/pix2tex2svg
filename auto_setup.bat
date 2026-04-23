@echo off
setlocal enabledelayedexpansion
title pix2tex2svg — Auto Setup

echo.
echo  =================================================
echo   pix2tex2svg  ^|  Auto Setup
echo  =================================================
echo.

:: ── Step 1: Locate or clone the repo ─────────────────────────────────────────
::
:: If this .bat is already inside the cloned repo (i.e. server.py exists next
:: to it), stay here.  Otherwise clone into a sibling folder.

if exist "%~dp0server.py" (
    echo [1/4] Already inside the repo folder.
    cd /d "%~dp0"
) else (
    echo [1/4] Cloning repository from GitHub...
    where git >nul 2>&1
    if errorlevel 1 (
        echo.
        echo  ERROR: git is not installed or not on PATH.
        echo  Download it from https://git-scm.com and re-run this script.
        echo.
        pause & exit /b 1
    )
    cd /d "%~dp0"
    git clone https://github.com/ElenBOT/pix2tex2svg.git
    if errorlevel 1 (
        echo.
        echo  ERROR: git clone failed. Check your internet connection.
        echo.
        pause & exit /b 1
    )
    cd pix2tex2svg
)

echo  Repo folder: %CD%
echo.

:: ── Step 2: Find Conda ────────────────────────────────────────────────────────
::
:: Searches the most common install locations for Miniconda / Anaconda.

echo [2/4] Searching for Conda installation...

set CONDA_ROOT=

for %%P in (
    "%USERPROFILE%\miniconda3"
    "%USERPROFILE%\Miniconda3"
    "%USERPROFILE%\anaconda3"
    "%USERPROFILE%\Anaconda3"
    "%LOCALAPPDATA%\miniconda3"
    "%LOCALAPPDATA%\Miniconda3"
    "%LOCALAPPDATA%\anaconda3"
    "%LOCALAPPDATA%\Anaconda3"
    "C:\miniconda3"
    "C:\Miniconda3"
    "C:\anaconda3"
    "C:\Anaconda3"
    "C:\ProgramData\miniconda3"
    "C:\ProgramData\Miniconda3"
    "C:\ProgramData\anaconda3"
    "C:\ProgramData\Anaconda3"
) do (
    if exist "%%~P\Scripts\conda.exe" (
        set "CONDA_ROOT=%%~P"
        goto :found_conda
    )
)

echo.
echo  ERROR: Could not find a Conda installation.
echo  Please install Miniconda from https://www.anaconda.com/download/success
echo  then re-run this script.
echo.
pause & exit /b 1

:found_conda
echo  Found Conda at: %CONDA_ROOT%
echo.

:: ── Step 3: Create the conda environment ─────────────────────────────────────

echo [3/4] Creating conda environment "pix2tex2svg" (Python 3.11)...
echo  (This may take a few minutes on first run)
echo.

call "%CONDA_ROOT%\Scripts\activate.bat" "%CONDA_ROOT%"

call conda create -n pix2tex2svg python=3.11 -y
if errorlevel 1 (
    echo.
    echo  ERROR: Failed to create conda environment.
    echo.
    pause & exit /b 1
)

call conda activate pix2tex2svg

:: ── Step 4: Install Python packages ──────────────────────────────────────────

echo.
echo [4/4] Installing Python packages...
echo  (pix2tex model weights ~1.5 GB will download on first OCR use)
echo.

pip install "pix2tex[api]" fastapi uvicorn pillow python-multipart
if errorlevel 1 (
    echo.
    echo  ERROR: pip install failed.
    echo.
    pause & exit /b 1
)

:: ── Done ──────────────────────────────────────────────────────────────────────

echo.
echo  =================================================
echo   Setup complete!
echo  =================================================
echo.
echo  To start the server, run:
echo.
echo      start_server.bat
echo.
echo  The server will print your LAN IP so other devices
echo  on the same Wi-Fi can open the app in their browser.
echo.
pause
endlocal
