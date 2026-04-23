#!/usr/bin/env python3
"""
pix2tex2svg backend server
Runs pix2tex OCR locally and exposes an HTTP API for the frontend.
"""

import io
import base64
import logging

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel
from PIL import Image

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="pix2tex2svg OCR API")

# Allow same-origin requests from the browser
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Lazy-load the model so startup is fast
_model = None

def get_model():
    global _model
    if _model is None:
        logger.info("Loading pix2tex LatexOCR model (first-time may download weights)…")
        from pix2tex.cli import LatexOCR
        _model = LatexOCR()
        logger.info("Model ready.")
    return _model


def image_to_latex(img: Image.Image) -> str:
    model = get_model()
    return model(img)


# ── Routes ────────────────────────────────────────────────────────────────────

class Base64Payload(BaseModel):
    image: str  # data-URI or raw base64 PNG/JPEG


@app.post("/ocr/base64")
async def ocr_base64(payload: Base64Payload):
    """Accept a base64-encoded image (data-URI or raw) and return LaTeX."""
    try:
        data = payload.image
        if data.startswith("data:"):
            # Strip the data-URI prefix
            data = data.split(",", 1)[1]
        img_bytes = base64.b64decode(data)
        img = Image.open(io.BytesIO(img_bytes)).convert("RGB")
        latex = image_to_latex(img)
        return {"latex": latex}
    except Exception as e:
        logger.exception("OCR failed")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/ocr/upload")
async def ocr_upload(file: UploadFile = File(...)):
    """Accept a multipart image upload and return LaTeX."""
    try:
        contents = await file.read()
        img = Image.open(io.BytesIO(contents)).convert("RGB")
        latex = image_to_latex(img)
        return {"latex": latex}
    except Exception as e:
        logger.exception("OCR failed")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/health")
async def health():
    return {"status": "ok"}


# ── Serve the static frontend ──────────────────────────────────────────────────
# Mount static files AFTER the API routes so /ocr/* is handled first.
app.mount("/", StaticFiles(directory=".", html=True), name="static")


def get_local_ip():
    """Returns the local IP address of the current machine."""
    import socket
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            return s.getsockname()[0]
    except Exception:
        return "127.0.0.1"

if __name__ == "__main__":
    import uvicorn
    ip = get_local_ip()
    print("\n" + "="*50)
    print(" pix2tex2svg | Server Running")
    print("="*50)
    print(f"\n Open this URL on any device on your Wi-Fi:\n\n     http://{ip}:7070\n")
    print("="*50 + "\n")
    uvicorn.run("server:app", host="0.0.0.0", port=7070, reload=False)
