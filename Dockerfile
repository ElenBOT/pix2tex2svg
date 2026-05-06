FROM python:3.10-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
# Install requirements (which now force PyTorch CPU-only version for lightweight Docker image)
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 7071

# Export PyTorch model → ONNX once at build time so the server uses the fast
# ONNX Runtime backend instead of PyTorch at runtime.
# The pix2tex weights are downloaded on first run via the pix2tex CLI init path.
RUN python -c "from pix2tex.cli import LatexOCR; LatexOCR()" && \
    python export_onnx.py && \
    python export_resizer.py

# Run generate_certs.py if ENABLE_HTTPS=1, then start server
CMD sh -c 'if [ "$ENABLE_HTTPS" = "1" ] && [ ! -f "cert.pem" ]; then python generate_certs.py; fi && python server.py'
