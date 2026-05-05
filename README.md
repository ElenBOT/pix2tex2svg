# pix2tex2svg

**Image → LaTeX → SVG** — paste or upload an equation screenshot, OCR it to LaTeX, then export as SVG/PNG/PDF. Runs entirely on your local machine or LAN.

## 1. Get the Code
```bash
git clone https://github.com/ElenBOT/pix2tex2svg.git
cd pix2tex2svg
```

## 2. Deployment (Docker - Recommended)

The easiest way to run the application is using Docker. This automatically handles dependencies and enables HTTPS for LAN access.

```bash
docker-compose up -d
```

*Note: The first time you run an OCR request, it will automatically download the model weights (~1.5 GB).*

## 3. Manual Setup & Run (Alternative)

If you prefer not to use Docker, you can run the server directly on your host.

**Windows (Automatic):**
1. Double-click `auto_setup.bat`. 
   *(Creates a `pix2tex2svg` env and installs dependencies).*
2. **(Optional but Recommended)** Double-click `enable_https.bat`.
   *This enables the **Paste** button on LAN devices by setting up a local SSL certificate.*
3. Double-click `start_server.bat`.

**Linux / macOS (Manual):**
```bash
pip install "pix2tex[api]" uvicorn fastapi pillow python-multipart cryptography
python server.py
```

## 4. Client Connect

Make sure you are on the **same Wi-Fi / LAN** as the server machine, and go to the URL shown in the server console (or `https://<SERVER-IP>:7071` if using Docker):
```
http://<SERVER-IP>:7071   (Standard)
https://<SERVER-IP>:7071  (If using Docker or if you ran enable_https.bat)
```

> **Note on HTTPS:** If using HTTPS, your browser will show a "Not Private" warning. Click **Advanced** -> **Proceed anyway**. This is required for the browser to allow the **Paste** button on LAN.

