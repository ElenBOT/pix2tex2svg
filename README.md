# pix2tex2svg

**Image → LaTeX → SVG** — paste or upload an equation screenshot, OCR it to LaTeX with [pix2tex](https://github.com/lukas-blecher/LaTeX-OCR), then export as SVG / PNG / PDF.

Runs entirely on your local machine or LAN. No cloud, no subscription, no data leaves your network.

---

## What it does

- 📋 **Paste clipboard image** — copy a screenshot of an equation and click Paste to OCR it instantly
- 📁 **Upload an image file** — pick any PNG/JPG containing a math equation
- ✏️ **Edit LaTeX** — tweak the recognised code, live preview updates as you type
- ⠿ **Drag to reorder** — rearrange equation rows by dragging the handle on the left
- 📤 **Export** — copy or download as SVG, PNG (4× density), or PDF

---

## Setup (server machine)

> This is the machine that runs the Python backend and serves the web app to everyone on the LAN.

### 1 — Install Python dependencies

```bash
pip install "pix2tex[api]" uvicorn fastapi pillow python-multipart
```

> **First OCR call** will download the pix2tex model weights (~1.5 GB) from HuggingFace automatically.

### 2 — Clone the repo

```bash
git clone https://github.com/ElenBOT/pix2tex2svg.git
cd pix2tex2svg
```

### 3 — Find your LAN IP address

**Linux / macOS**
```bash
hostname -I        # Linux
ipconfig getifaddr en0   # macOS (Wi-Fi)
```

**Windows**
```
ipconfig           # look for "IPv4 Address" under your Wi-Fi adapter
```

Your IP will look like `192.168.x.x` or `10.0.x.x`. Note it down — clients will need it.

### 4 — Start the server

```bash
python server.py
```

You should see:
```
INFO:     Uvicorn running on http://0.0.0.0:7070
```

The server:
- Listens on **all** network interfaces (LAN-accessible)
- Serves the web app **and** the OCR API from the same port
- Keeps running until you press `Ctrl+C`

### 5 — Open in your own browser

```
http://localhost:7070
```

---

## Accessing from another device on the LAN (client)

No installation needed on client devices — just a modern browser.

1. Make sure the client is on the **same Wi-Fi / network** as the server machine
2. Open a browser and go to:

```
http://<SERVER-IP>:7070
```

Replace `<SERVER-IP>` with the IP you found in Step 3, e.g.:

```
http://192.168.1.42:7070
```

3. The green **"OCR server online"** dot in the top bar confirms the connection is working.

> **Firewall note:** If clients can't connect, you may need to allow port `7070` through the server's firewall:
> ```bash
> # Linux (ufw)
> sudo ufw allow 7070
> ```

---

## Tech stack

| Layer | Technology |
|---|---|
| OCR model | [pix2tex](https://github.com/lukas-blecher/LaTeX-OCR) (ViT + transformer) |
| Backend | FastAPI + Uvicorn |
| Math rendering | MathJax v4 (`tex-svg`) |
| PDF export | jsPDF + svg2pdf.js |
| UI font | Inter (Google Fonts) |
| Frontend | Plain HTML / CSS / JS — no build step |

---

## License

MIT
