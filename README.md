# pix2tex2svg

**Image → LaTeX → SVG** — paste or upload an equation screenshot, OCR it to LaTeX, then export as SVG/PNG/PDF. Runs entirely on your local machine or LAN.

## 1. Get the Code
```bash
git clone https://github.com/ElenBOT/pix2tex2svg.git
cd pix2tex2svg
```

## 2. Deployment

The project uses Docker as the unified deployment method. This automatically handles all dependencies and natively sets up HTTPS for LAN access.

```bash
docker compose up -d
```

*Note: The first time you run an OCR request, it will automatically download the model weights (~1.5 GB).*

## 3. Client Connect

Make sure you are on the **same Wi-Fi / LAN** as the server machine, and go to the following URL in your browser:
```
https://<SERVER-IP>:7071
```

> **Note on HTTPS:** Because the server generates a self-signed certificate, your browser will show a "Not Private" warning. Click **Advanced** -> **Proceed anyway**. This is strictly required for your browser to grant access to your clipboard, allowing you to use the **Paste** button across the LAN.
