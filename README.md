# pix2tex2svg

**Image → LaTeX → SVG** — paste or upload an equation screenshot, OCR it to LaTeX, then export as SVG/PNG/PDF. Runs entirely on your local machine or LAN.

## How It Works

OCR is powered by **[pix2tex](https://github.com/lukas-blecher/LaTeX-OCR)** by Lukas Blecher. To reduce image size and eliminate heavy dependencies at runtime, the PyTorch model has been pre-converted to **ONNX format** and bundled directly in this repository. The server runs on lightweight [ONNX Runtime](https://onnxruntime.ai/) — no PyTorch or pix2tex installation required.

## 1. Get the Code

```bash
git clone https://github.com/ElenBOT/pix2tex2svg.git
cd pix2tex2svg
git checkout feat/onnx-backend
```

## 2. Deployment

The project uses Docker as the unified deployment method. This automatically handles all dependencies and natively sets up HTTPS for LAN access.

```bash
docker compose up -d --build
```

The pre-built ONNX model weights (`encoder.onnx`, `decoder.onnx`) are already included in the repository, so there is **no model download step** at runtime. The container image is also significantly smaller (~500 MB) compared to a full PyTorch setup.

## 3. Client Connect

Make sure you are on the **same Wi-Fi / LAN** as the server machine, and go to the following URL in your browser:
```
https://<SERVER-IP>:7071
```

> **Note on HTTPS:** Because the server generates a self-signed certificate, your browser will show a "Not Private" warning. Click **Advanced** → **Proceed anyway**. This is strictly required for your browser to grant access to your clipboard, allowing you to use the **Paste** button across the LAN.

---

## For Developers — Updating the ONNX Models

The ONNX weights in this repo were exported from the original pix2tex PyTorch checkpoint. If you need to re-export them (e.g. after a pix2tex update), install the dev dependencies and run the export scripts on your own machine:

```bash
pip install -r requirements-dev.txt
python export_onnx.py        # generates encoder.onnx + decoder.onnx
python export_resizer.py     # generates image_resizer.onnx
git add *.onnx tokenizer.json
git commit -m "chore: update ONNX weights"
git push
```

Deployment servers only need `requirements.txt` (slim runtime, no PyTorch).
