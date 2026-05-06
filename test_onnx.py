"""
Sanity-test for ONNXLatexOCR vs the original pix2tex LatexOCR.

Run from the project root:
    python test_onnx.py

Requires:
  - encoder.onnx and decoder.onnx to exist (run export_onnx.py first)
  - pix2tex installed in the current python environment (for ground-truth comparison)
"""
import time
import numpy as np
from PIL import Image, ImageDraw, ImageFont


def make_test_image(text: str = "E = mc^2") -> Image.Image:
    """Generate a simple white-background grayscale image with math text."""
    W, H = 256, 64
    img = Image.new("RGB", (W, H), color="white")
    draw = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 24)
    except Exception:
        font = ImageFont.load_default()
    draw.text((10, 15), text, fill="black", font=font)
    return img


# ── 1. Load ONNX model ────────────────────────────────────────────────────────
print("=" * 60)
print("Loading ONNX model ...")
t0 = time.time()
from onnx_inference import ONNXLatexOCR
onnx_model = ONNXLatexOCR("encoder.onnx", "decoder.onnx")
print(f"  ONNX model loaded in {time.time()-t0:.2f}s")

# ── 2. Load original PyTorch model ───────────────────────────────────────────
print("Loading PyTorch model ...")
t0 = time.time()
from pix2tex.cli import LatexOCR
pt_model = LatexOCR()
print(f"  PyTorch model loaded in {time.time()-t0:.2f}s")

# ── 3. Run inference on a few test images ────────────────────────────────────
test_cases = [
    make_test_image("E = mc^2"),
    make_test_image("\\int_0^1 x dx"),
    make_test_image("a^2 + b^2 = c^2"),
]

print("\n" + "=" * 60)
print("Running inference comparison:")
print("=" * 60)

for i, img in enumerate(test_cases, 1):
    print(f"\n[Test {i}]")

    # ONNX
    t0 = time.time()
    onnx_result = onnx_model(img.copy())
    onnx_time = time.time() - t0

    # PyTorch
    t0 = time.time()
    pt_result = pt_model(img.copy())
    pt_time = time.time() - t0

    print(f"  PyTorch : {pt_result!r:<50}  ({pt_time*1000:.0f} ms)")
    print(f"  ONNX    : {onnx_result!r:<50}  ({onnx_time*1000:.0f} ms)")
    speedup = pt_time / onnx_time if onnx_time > 0 else float('inf')
    print(f"  Speedup : {speedup:.2f}x")

print("\n" + "=" * 60)
print("✅  Test complete.")
