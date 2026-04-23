@echo off
setlocal
title pix2tex2svg - Auto Setup

echo.
echo  =================================================
echo   pix2tex2svg  ^|  Auto Setup
echo  =================================================
echo.

:: -- Step 1: Update code --
if exist .git (
    echo [1/4] Updating repository...
    git pull
)
echo.

:: -- Step 2: Find Conda --
echo [2/4] Searching for Conda...
set "CONDA_PATH="

:: Try PATH first
where conda >nul 2>&1
if %errorlevel% == 0 (
    for /f "tokens=*" %%i in ('where conda') do (
        set "TEMP_PATH=%%~dpi"
        set "CONDA_PATH=!TEMP_PATH!\.."
    )
)

:: Common install paths
if "%CONDA_PATH%"=="" (
    if exist "%USERPROFILE%\miniconda3\Scripts\conda.exe" set "CONDA_PATH=%USERPROFILE%\miniconda3"
    if exist "%USERPROFILE%\anaconda3\Scripts\conda.exe" set "CONDA_PATH=%USERPROFILE%\anaconda3"
    if exist "%LOCALAPPDATA%\miniconda3\Scripts\conda.exe" set "CONDA_PATH=%LOCALAPPDATA%\miniconda3"
    if exist "C:\miniconda3\Scripts\conda.exe" set "CONDA_PATH=C:\miniconda3"
    if exist "C:\anaconda3\Scripts\conda.exe" set "CONDA_PATH=C:\anaconda3"
    if exist "C:\ProgramData\miniconda3\Scripts\conda.exe" set "CONDA_PATH=C:\ProgramData\miniconda3"
    if exist "C:\ProgramData\Anaconda3\Scripts\conda.exe" set "CONDA_PATH=C:\ProgramData\Anaconda3"
)

if "%CONDA_PATH%"=="" (
    echo  ERROR: Could not find a Conda installation.
    echo  Please install Miniconda or Anaconda then re-run this script.
    echo.
    pause
    exit /b 1
)
echo  Found Conda at: %CONDA_PATH%
echo.

:: -- Step 3: Activate and Check Env --
echo [3/4] Setting up environment...
call "%CONDA_PATH%\Scripts\activate.bat" "%CONDA_PATH%"

:: Check if environment exists
call conda activate pix2tex2svg 2>nul
if errorlevel 1 (
    echo  Creating environment 'pix2tex2svg' (Python 3.11)...
    call conda create -n pix2tex2svg python=3.11 -y
    call conda activate pix2tex2svg
) else (
    echo  Environment 'pix2tex2svg' already exists.
)
echo.

:: -- Step 4: Install --
echo [4/4] Installing/Updating packages...
pip install "pix2tex[api]" fastapi uvicorn pillow python-multipart cryptography
if errorlevel 1 (
    echo.
    echo  ERROR: Pip install failed.
    echo.
    pause
    exit /b 1
)

echo.
echo  =================================================
echo   Setup complete! Run start_server.bat to begin.
echo  =================================================
echo.
pause
endlocal


