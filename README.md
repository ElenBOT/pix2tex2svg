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

### Windows — one-click setup ✨

Two batch files are provided for a zero-effort Windows setup.

**Step 1 — Run `auto_setup.bat`** (one time only)

Download or clone this repo, then double-click `auto_setup.bat`. It will:
1. Clone the repo if it isn't already present
2. Search for your Miniconda / Anaconda installation automatically
3. Create a `pix2tex2svg` conda environment with Python 3.11
4. Install all required packages (`pix2tex`, `fastapi`, `uvicorn`, etc.)

> **Prerequisite:** [Git](https://git-scm.com) and [Miniconda](https://www.anaconda.com/download/success) (or Anaconda) must be installed.  
> **First OCR call** will download the pix2tex model weights (~1.5 GB) from HuggingFace automatically.

**Step 2 — Run `start_server.bat`** (every time you want to use the app)

Double-click `start_server.bat`. It will:
- Activate the `pix2tex2svg` conda environment
- Print your LAN IP address(es), e.g.:

  ```
  http://192.168.1.42:7070
  ```

- Launch the server — keep this window open while using the app

Share the printed URL with anyone on the same Wi-Fi. Press `Ctrl+C` to stop.

---

### Linux / macOS — manual setup

**1 — Clone the repo**

```bash
git clone https://github.com/ElenBOT/pix2tex2svg.git
cd pix2tex2svg
```

**2 — Install Python dependencies**

```bash
pip install "pix2tex[api]" uvicorn fastapi pillow python-multipart
```

> **First OCR call** will download the pix2tex model weights (~1.5 GB) from HuggingFace automatically.

**3 — Find your LAN IP address**

```bash
hostname -I              # Linux — pick the 192.168.x.x or 10.x.x.x address
ipconfig getifaddr en0   # macOS (Wi-Fi)
```

**4 — Start the server**

```bash
python server.py
```

```
INFO:     Uvicorn running on http://0.0.0.0:7070
```

Open `http://localhost:7070` on the server machine, or share `http://<YOUR-LAN-IP>:7070` with others on the same network.

---

## Accessing from another device on the LAN (client)

No installation needed on client devices — just a modern browser.

1. Make sure the client is on the **same Wi-Fi / network** as the server machine
2. Open a browser and go to:

```
http://<SERVER-IP>:7070
```

For example: `http://192.168.1.42:7070`

3. The green **"OCR server online"** dot in the top bar confirms the connection is working.

> **Firewall note:** If clients can't connect, allow port `7070` through the server's firewall:
> ```bash
> # Linux (ufw)
> sudo ufw allow 7070
> ```
> On Windows, the first time you run the server Windows Defender Firewall may ask for permission — click **Allow**.

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
