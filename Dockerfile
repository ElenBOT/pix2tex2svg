FROM python:3.10-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
# Install slim runtime deps only (no PyTorch, no pix2tex)
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 7071

# Run generate_certs.py if ENABLE_HTTPS=1, then start server
CMD sh -c 'if [ "$ENABLE_HTTPS" = "1" ] && [ ! -f "cert.pem" ]; then python generate_certs.py; fi && python server.py'
