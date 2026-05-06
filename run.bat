@echo off
:: ─────────────────────────────────────────────────────────────────────────────
:: pix2tex2svg — Startup Script (venv mode, Windows)
:: ─────────────────────────────────────────────────────────────────────────────

cd /d "%~dp0"

:: 1. Check for Python
python --version >nul 2>&1
if errorlevel 1 (
    echo Error: python is not installed or not in PATH.
    pause
    exit /b 1
)

:: 2. Setup virtual environment if missing
if not exist "venv" (
    echo Creating virtual environment...
    python -m venv venv
)

:: 3. Install/Update dependencies
echo Checking dependencies...
venv\Scripts\pip install --upgrade pip
venv\Scripts\pip install -r requirements.txt

:: 4. Generate SSL Certificates (if missing)
if not exist "cert.pem" (
    echo Generating SSL certificates for HTTPS...
    venv\Scripts\python generate_certs.py
)

:: 5. Run Server
echo Starting server...
venv\Scripts\python server.py

pause
