@echo off
setlocal enabledelayedexpansion
title pix2tex2svg - Auto Setup

echo.
echo  =================================================
echo   pix2tex2svg  ^|  Auto Setup
echo  =================================================
echo.

:: -- Step 1: Update code ------------------------------------------------------
if exist "%~dp0.git" (
    echo [1/4] Updating repository with latest code...
    cd /d "%~dp0"
    git pull
) else (
    echo [1/4] Initializing repository...
    if not exist "%~dp0server.py" (
        where git >nul 2>&1
        if errorlevel 1 (
            echo.
            echo  ERROR: git is not installed. 
            echo  Download it from https://git-scm.com
            echo.
            pause & exit /b 1
        )
        cd /d "%~dp0"
        git clone https://github.com/ElenBOT/pix2tex2svg.git .
    )
)

echo.

:: -- Step 2: Find Conda --------------------------------------------------------
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
echo  Please install Miniconda or Anaconda then re-run this script.
echo.
pause & exit /b 1

:found_conda
echo  Found Conda at: %CONDA_ROOT%
echo.

:: -- Step 3: Handle Environment ----------------------------------------------
echo [3/4] Ensuring Conda environment "pix2tex2svg" exists...

call "%CONDA_ROOT%\Scripts\activate.bat" "%CONDA_ROOT%"

:: Check if env exists (using a more robust check)
call conda env list | findstr /C:"pix2tex2svg " >nul
if errorlevel 1 (
    echo  Creating new environment (Python 3.11)...
    call conda create -n pix2tex2svg python=3.11 -y
    if errorlevel 1 (
        echo.
        echo  ERROR: Failed to create conda environment.
        echo.
        pause & exit /b 1
    )
) else (
    echo  Environment 'pix2tex2svg' already exists.
)

echo.

:: -- Step 4: Install/Update Packages -----------------------------------------
echo [4/4] Activating environment and updating Python packages...
call conda activate pix2tex2svg

pip install "pix2tex[api]" fastapi uvicorn pillow python-multipart cryptography
if errorlevel 1 (
    echo.
    echo  ERROR: pip install failed.
    echo.
    pause & exit /b 1
)

:: -- Done ----------------------------------------------------------------------

echo.
echo  =================================================
echo   Setup complete!
echo  =================================================
echo.
echo  To start the server, run:
echo.
echo      start_server.bat
echo.
pause
endlocal

