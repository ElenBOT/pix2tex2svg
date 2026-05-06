#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# pix2tex2svg — Startup Script (venv mode)
# ─────────────────────────────────────────────────────────────────────────────

# Change to the script's directory
cd "$(dirname "$0")"

# 1. Check for Python
if ! command -v python3 &> /dev/null; then
    echo "Error: python3 is not installed."
    exit 1
fi

# 2. Setup virtual environment if missing
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# 3. Activate venv
source venv/bin/activate

# 4. Install/Update dependencies
echo "Checking dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# 5. Generate SSL Certificates (if missing)
if [ ! -f "cert.pem" ]; then
    echo "Generating SSL certificates for HTTPS..."
    python generate_certs.py
fi

# 6. Run Server
echo "Starting server..."
python server.py
