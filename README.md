# pix2tex2svg

**Image → LaTeX → SVG** — paste or upload an equation screenshot, OCR it to LaTeX, then export as SVG/PNG/PDF. Runs entirely on your local machine or LAN.

## 1. Get the Code
```bash
git clone https://github.com/ElenBOT/pix2tex2svg.git
cd pix2tex2svg
```

## 2. Setup

**Windows (Automatic):**
Double-click `auto_setup.bat`. 
*(Requires Miniconda/Anaconda. It automatically creates a `pix2tex2svg` env and installs dependencies).*

**Linux / macOS (Manual):**
```bash
pip install "pix2tex[api]" uvicorn fastapi pillow python-multipart
```

## 3. Start Server

**Windows:**
Double-click `start_server.bat`. It will launch the server and print your LAN IP automatically.

**Linux / macOS:**
```bash
python server.py
# Find your IP using: hostname -I (Linux) or ipconfig getifaddr en0 (macOS)
```

> **Note:** The first time you run an OCR request, it will automatically download the model weights (~1.5 GB).

## 4. Client Connect

No installation needed on client devices! Simply make sure you are on the **same Wi-Fi / LAN** as the server machine, open a browser, and go to:
```
http://<SERVER-IP>:7070
```
*(A green "OCR server online" dot in the top bar will confirm the connection).*
