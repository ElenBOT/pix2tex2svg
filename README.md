# pix2tex2svg

**Image → LaTeX → SVG** — paste or upload an equation screenshot, OCR it to LaTeX, then export as SVG/PNG/PDF. Runs entirely on your local machine or LAN.

## 1. Get the Code
```bash
git clone https://github.com/ElenBOT/pix2tex2svg.git
cd pix2tex2svg
```

## 2. Setup

**Windows (Automatic):**
1. Double-click `auto_setup.bat`. 
   *(Creates a `pix2tex2svg` env and installs dependencies).*
2. **(Optional but Recommended)** Double-click `enable_https.bat`.
   *This enables the **Paste** button on LAN devices by setting up a local SSL certificate.*

**Linux / macOS (Manual):**
```bash
pip install "pix2tex[api]" uvicorn fastapi pillow python-multipart cryptography
```

## 3. Start Server

**Windows:**
Double-click `start_server.bat`. 

**Linux / macOS:**
```bash
python server.py
```

> **Note:** The first time you run an OCR request, it will automatically download the model weights (~1.5 GB).

## 4. Client Connect

Make sure you are on the **same Wi-Fi / LAN** as the server machine, and go to the URL shown in the server console:
```
http://<SERVER-IP>:7070   (Standard)
https://<SERVER-IP>:7070  (If you ran enable_https.bat)
```

> **Note on HTTPS:** If using HTTPS, your browser will show a "Not Private" warning. Click **Advanced** -> **Proceed anyway**. This is required for the browser to allow the **Paste** button on LAN.

