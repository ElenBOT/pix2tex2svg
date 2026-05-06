# pix2tex2svg

**Image → LaTeX → SVG** — paste or upload an equation screenshot, OCR it to LaTeX, then export as SVG/PNG/PDF. Runs entirely on your local machine or LAN.

<img width="1019" height="552" alt="image" src="https://github.com/user-attachments/assets/25359f64-6c76-43f0-91fd-9fa54052c41c" />

### Easy setup: 
* Server side: Get the Code -> Deployment. (See Below)
* Client side: Go to web browser for `https://<SERVER-IP>:7071`.

## How It Works

OCR is powered by **[pix2tex](https://github.com/lukas-blecher/LaTeX-OCR)** by Lukas Blecher. To reduce image size and eliminate heavy dependencies at runtime, the PyTorch model has been pre-converted to **ONNX format** and bundled directly in this repository. The server runs on lightweight [ONNX Runtime](https://onnxruntime.ai/) — no PyTorch or pix2tex installation required.

## 1. Get the Code

```bash
git clone https://github.com/ElenBOT/pix2tex2svg.git
```

```bash
cd pix2tex2svg
```
## 2. Deployment

### Option A: Docker (Recommended)
Best for isolation and cross-platform consistency. Handles all system dependencies automatically.

```bash
docker compose up -d
```

**Manage the service:**
```bash
# View logs
docker compose logs -f

# Stop the service
docker compose stop

# Restart the service
docker compose start
```

### Option B: Conda (Recommended)
Best if you already use Miniconda/Anaconda (works on all platforms including Windows).

```bash
# First time setup
conda env create -f environment.yml

# Every time after
conda activate pix2tex2svg
python generate_certs.py
python server.py
```

### Option C: Local Shell + venv (Native)
For users who want to run Python natively on the host OS.

```bash
# Linux / macOS
chmod +x run.sh
./run.sh
```

```bash
# Windows
run.bat
```

### Option D: Systemd Service (Linux Edge Devices)
Best for dedicated Linux servers or edge devices (e.g., Raspberry Pi) where you want the service to start automatically on boot and restart if it crashes.

1.  Setup the virtual environment first: `./run.sh` (then stop it with Ctrl+C).
2.  Edit `pix2tex2svg.service` and update the `WorkingDirectory` and `ExecStart` paths.
3.  Deploy the service:
    ```bash
    sudo cp pix2tex2svg.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable pix2tex2svg
    sudo systemctl start pix2tex2svg
    ```
4.  Check logs: `journalctl -u pix2tex2svg -f`

> **Note on Model Weights:** The pre-built ONNX weights (`encoder.onnx`, `decoder.onnx`) are already included in the repository. There is **no large model download step** required at runtime for any of these methods.

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

---

## Technical Note: The Challenges of ONNX Export

Converting Pix2Tex to a standalone ONNX backend was a non-trivial task due to several architecture-specific hurdles:

1.  **Decoder Autoregression**: The Pix2Tex decoder is a causal transformer that predicts one token at a time. To run this in ONNX without PyTorch, we had to implement the autoregressive loop in Python using NumPy, feeding the output of each step back into the model until an `[EOS]` (End Of Sequence) token is reached.
2.  **Tokenizer Compatibility**: The original model uses a Byte-Level BPE tokenizer with specific post-processing logic (handling 'Ġ' characters and LaTeX syntax cleaning). We successfully replicated this logic using `transformers.PreTrainedTokenizerFast` and custom string post-processors to ensure the OCR output matches the original PyTorch implementation's fidelity.
3.  **Image Resizer Logic**: Pix2Tex uses a separate "Image Resizer" model to normalize input shapes. This was also exported to ONNX to ensure that the entire preprocessing pipeline remains independent of PyTorch.
4.  **Static vs Dynamic Axes**: Ensuring the models could handle variable input image sizes and variable output sequence lengths required careful definition of dynamic axes during the export process.

---

## License

This project is licensed under the [MIT License](LICENSE).

