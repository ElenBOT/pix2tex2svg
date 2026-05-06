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
        import os
        # Use absolute path so it works both locally and inside Docker volume mounts
        base_dir = os.path.dirname(os.path.abspath(__file__))
        encoder_path = os.path.join(base_dir, "encoder.onnx")
        decoder_path = os.path.join(base_dir, "decoder.onnx")

        if os.path.exists(encoder_path) and os.path.exists(decoder_path):
            logger.info("ONNX weights found — loading lightweight ONNX backend…")
            from onnx_inference import ONNXLatexOCR
            _model = ONNXLatexOCR(encoder_path, decoder_path)
            logger.info("ONNX model ready.")
        else:
            raise RuntimeError(
                f"ONNX model files not found:\n  {encoder_path}\n  {decoder_path}\n"
                "Please run 'python export_onnx.py' on your dev machine and commit the .onnx files."
            )
    return _model


def image_to_latex(img: Image.Image) -> str:
    model = get_model()
    return model(img)


# ── Routes ────────────────────────────────────────────────────────────────────

class Base64Payload(BaseModel):
    image: str  # data-URI or raw base64 PNG/JPEG


@app.post("/ocr/base64")
def ocr_base64(payload: Base64Payload):
    """Accept a base64-encoded image (data-URI or raw) and return LaTeX."""
    try:
        data = payload.image
        if data.startswith("data:"):
            # Strip the data-URI prefix
            data = data.split(",", 1)[1]
        img_bytes = base64.b64decode(data)
        img = Image.open(io.BytesIO(img_bytes))
        
        # Blend transparent background with white
        if img.mode in ('RGBA', 'LA') or (img.mode == 'P' and 'transparency' in img.info):
            if img.mode != 'RGBA':
                img = img.convert('RGBA')
            bg = Image.new('RGBA', img.size, (255, 255, 255, 255))
            bg.paste(img, mask=img)
            img = bg.convert("RGB")
        else:
            img = img.convert("RGB")
            
        latex = image_to_latex(img)
        return {"latex": latex}
    except Exception as e:
        logger.exception("OCR failed")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/ocr/upload")
def ocr_upload(file: UploadFile = File(...)):
    """Accept a multipart image upload and return LaTeX."""
    try:
        contents = file.file.read()
        img = Image.open(io.BytesIO(contents))
        
        if img.mode in ('RGBA', 'LA') or (img.mode == 'P' and 'transparency' in img.info):
            if img.mode != 'RGBA':
                img = img.convert('RGBA')
            bg = Image.new('RGBA', img.size, (255, 255, 255, 255))
            bg.paste(img, mask=img)
            img = bg.convert("RGB")
        else:
            img = img.convert("RGB")
            
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


def get_all_local_ips():
    """Returns all local IP addresses of the current machine."""
    import socket
    ips = []
    try:
        # This grabs all IPs on Windows natively
        host_name = socket.gethostname()
        ips.extend(socket.gethostbyname_ex(host_name)[2])
    except Exception:
        pass
    
    try:
        # Fallback/guarantee for primary routed IP
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            ips.append(s.getsockname()[0])
    except Exception:
        pass

    # Filter loopbacks and deduplicate
    valid_ips = list(set([ip for ip in ips if not ip.startswith("127.")]))
    return valid_ips if valid_ips else ["127.0.0.1"]

if __name__ == "__main__":
    import uvicorn
    import os
    
    ips = get_all_local_ips()
    port = int(os.environ.get("PORT", 7071))
    
    # Check for SSL certificates
    ssl_key = "key.pem"
    ssl_cert = "cert.pem"
    use_ssl = os.path.exists(ssl_key) and os.path.exists(ssl_cert)
    protocol = "https" if use_ssl else "http"
    
    print("\n" + "="*50)
    print(f" pix2tex2svg | Server Running ({protocol.upper()})")
    print("="*50)
    print("\n Open one of these URLs on any device on your Wi-Fi:\n")
    for ip in ips:
        print(f"     {protocol}://{ip}:{port}")
    
    if use_ssl:
        print("\n [SSL Active] Browser will show a warning. Proceed manually.")
    
    print("\n" + "="*50 + "\n")
    
    if use_ssl:
        uvicorn.run("server:app", host="0.0.0.0", port=port, reload=False, ssl_keyfile=ssl_key, ssl_certfile=ssl_cert)
    else:
        uvicorn.run("server:app", host="0.0.0.0", port=port, reload=False)
