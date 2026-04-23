@echo off
setlocal enabledelayedexpansion
title pix2tex2svg — Server

:: ── Locate repo root (same folder as this .bat) ───────────────────────────────
cd /d "%~dp0"

if not exist "server.py" (
    echo.
    echo  ERROR: server.py not found next to this script.
    echo  Make sure start_server.bat is in the pix2tex2svg folder.
    echo.
    pause & exit /b 1
)

:: ── Find Conda ────────────────────────────────────────────────────────────────
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
echo  ERROR: Conda not found. Run auto_setup.bat first.
echo.
pause & exit /b 1

:found_conda
call "%CONDA_ROOT%\Scripts\activate.bat" "%CONDA_ROOT%"
call conda activate pix2tex2svg

if errorlevel 1 (
    echo.
    echo  ERROR: Could not activate "pix2tex2svg" environment.
    echo  Run auto_setup.bat first to create it.
    echo.
    pause & exit /b 1
)

:: ── Collect LAN IP addresses ──────────────────────────────────────────────────
::
:: ipconfig lists multiple adapters; we pick lines that contain "IPv4 Address"
:: and skip loopback (127.x).

echo.
echo  =================================================
echo   pix2tex2svg  ^|  Starting Server
echo  =================================================
echo.
echo  Your LAN address(es) — share one with clients:
echo.

python -c "import socket; ips=[ip for ip in socket.gethostbyname_ex(socket.gethostname())[2] if not ip.startswith('127.')]; print('\n'.join(['      http://'+ip+':7070' for ip in ips]) if ips else '      (Could not detect LAN IP)')"

echo.
echo  Open the above URL on any device on the same Wi-Fi.
echo  This window must stay open while the server is running.
echo  Press Ctrl+C to stop.
echo.
echo  -------------------------------------------------
echo.

:: ── Launch server ─────────────────────────────────────────────────────────────
python server.py

:: If server exits, pause so the window stays open to show any error
echo.
echo  Server stopped.
pause
endlocal
