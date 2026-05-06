"""
ONNXLatexOCR — Lightweight inference wrapper that replaces the PyTorch pix2tex
pipeline with pure ONNX Runtime, eliminating the torch dependency at runtime.

Usage:
    model = ONNXLatexOCR()
    latex = model(pil_image)
"""
import os
import re
import numpy as np
from PIL import Image
from typing import Optional, Tuple, List

import onnxruntime as ort
from transformers import PreTrainedTokenizerFast

# Directory where this file lives (= project root in both local and Docker)
_HERE = os.path.dirname(os.path.abspath(__file__))


# ── Image utilities (mirrors pix2tex internals, no torch needed) ──────────────

def _pad(img: Image.Image, divable: int = 32) -> Image.Image:
    """Pad image so both dimensions are multiples of `divable`."""
    w, h = img.size
    pw = (divable - w % divable) % divable
    ph = (divable - h % divable) % divable
    if pw == 0 and ph == 0:
        return img
    bg = Image.new("RGB", (w + pw, h + ph), (255, 255, 255))
    bg.paste(img, (0, 0))
    return bg


def _minmax_size(
    img: Image.Image,
    max_dim: Optional[List[int]] = None,
    min_dim: Optional[List[int]] = None,
) -> Image.Image:
    if max_dim is not None:
        ratios = [a / b for a, b in zip(img.size, max_dim)]
        if any(r > 1 for r in ratios):
            size = (np.array(img.size) // max(ratios)).astype(int)
            img = img.resize(tuple(size), Image.Resampling.BILINEAR)
    if min_dim is not None:
        padded_size = [max(a, b) for a, b in zip(img.size, min_dim)]
        if padded_size != list(img.size):
            bg = Image.new("L", padded_size, 255)
            bg.paste(img, img.getbbox())
            img = bg
    return img


def _token2str(tokens: list, tokenizer: PreTrainedTokenizerFast) -> str:
    """Mirrors pix2tex.utils.token2str — joins BPE pieces and replaces Ġ with space."""
    dec = tokenizer.decode(tokens)
    return ''.join(dec.split(' ')).replace('Ġ', ' ').replace('[EOS]', '').replace('[BOS]', '').replace('[PAD]', '').strip()


def _post_process(s: str) -> str:
    """Mirrors pix2tex.utils.post_process to clean up tokenizer output."""
    text_reg = r"(\\(operatorname|mathrm|text|mathbf)\s?\*? {.*?})"
    letter = "[a-zA-Z]"
    noletter = r"[\W_^\d]"
    names = [x[0].replace(" ", "") for x in re.findall(text_reg, s)]
    s = re.sub(text_reg, lambda m: str(names.pop(0)), s)
    news = s
    while True:
        s = news
        news = re.sub(r"(?!\\ )(%s)\s+?(%s)" % (noletter, noletter), r"\1\2", s)
        news = re.sub(r"(?!\\ )(%s)\s+?(%s)" % (noletter, letter), r"\1\2", news)
        news = re.sub(r"(%s)\s+?(%s)" % (letter, noletter), r"\1\2", news)
        if news == s:
            break
    return s


# ── Main class ─────────────────────────────────────────────────────────────────

class ONNXLatexOCR:
    """
    Drop-in ONNX Runtime replacement for pix2tex.cli.LatexOCR.
    Requires encoder.onnx and decoder.onnx (exported via export_onnx.py).
    """

    # Hard-coded model hyper-parameters (match pix2tex config.yaml)
    MAX_SEQ_LEN   = 512
    BOS_TOKEN     = 1
    EOS_TOKEN     = 2
    TEMPERATURE   = 0.25
    MAX_DIM       = [672, 192]
    MIN_DIM       = [32, 32]
    IMG_MEAN      = 0.7931
    IMG_STD       = 0.1738

    def __init__(
        self,
        encoder_path: str = "encoder.onnx",
        decoder_path: str = "decoder.onnx",
        tokenizer_path: Optional[str] = None,
    ):
        # Resolve tokenizer: look in project dir first, then fall back to pix2tex install
        if tokenizer_path is None:
            local_tok = os.path.join(_HERE, "tokenizer.json")
            if os.path.exists(local_tok):
                tokenizer_path = local_tok
            else:
                # Last-resort fallback: try finding pix2tex in site-packages
                import site
                for sp in site.getsitepackages():
                    candidate = os.path.join(sp, "pix2tex", "model", "dataset", "tokenizer.json")
                    if os.path.exists(candidate):
                        tokenizer_path = candidate
                        break
                if tokenizer_path is None:
                    raise RuntimeError(
                        "tokenizer.json not found. Expected at: " + local_tok + "\n"
                        "Copy it from pix2tex/model/dataset/tokenizer.json into the project root."
                    )
        self.tokenizer = PreTrainedTokenizerFast(tokenizer_file=tokenizer_path)

        # ONNX sessions with full graph optimization
        opts = ort.SessionOptions()
        opts.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
        providers = ["CPUExecutionProvider"]

        self.enc = ort.InferenceSession(encoder_path, opts, providers=providers)
        self.dec = ort.InferenceSession(decoder_path, opts, providers=providers)

        # Cache input names
        self._enc_in  = self.enc.get_inputs()[0].name   # "images"
        self._dec_x   = self.dec.get_inputs()[0].name   # "x"
        self._dec_ctx = self.dec.get_inputs()[1].name   # "context"

    # ── Pre-processing ─────────────────────────────────────────────────────────

    def _preprocess(self, img: Image.Image) -> np.ndarray:
        """RGB PIL → (1, 1, H, W) float32 tensor, normalised."""
        img = img.convert("RGB")
        img = _minmax_size(_pad(img), self.MAX_DIM, self.MIN_DIM)

        # Convert to grayscale (matches albumentations ToGray on RGB)
        img_gray = img.convert("L")
        arr = np.array(img_gray, dtype=np.float32) / 255.0
        arr = (arr - self.IMG_MEAN) / self.IMG_STD
        return arr[None, None].astype(np.float32)  # (1, 1, H, W)

    # ── Inference ──────────────────────────────────────────────────────────────

    def __call__(self, img: Image.Image) -> str:
        im = self._preprocess(img)

        # 1. Encode image → context vector
        context = self.enc.run(None, {self._enc_in: im})[0]   # (1, N, D)

        # 2. Autoregressive decode
        out = np.array([[self.BOS_TOKEN]], dtype=np.int64)

        for _ in range(self.MAX_SEQ_LEN):
            x = out[:, -self.MAX_SEQ_LEN:]
            logits = self.dec.run(None, {self._dec_x: x, self._dec_ctx: context})[0]
            logits_last = logits[:, -1, :]  # (1, vocab)

            # Temperature-scaled multinomial sampling (same as pix2tex)
            shifted = logits_last / self.TEMPERATURE
            shifted -= shifted.max()            # numerical stability
            probs = np.exp(shifted)
            probs /= probs.sum()
            next_tok = np.array([[np.random.choice(len(probs[0]), p=probs[0])]], dtype=np.int64)

            out = np.concatenate([out, next_tok], axis=1)
            if next_tok[0, 0] == self.EOS_TOKEN:
                break

        # 3. Decode token IDs → string (mirrors pix2tex token2str + post_process)
        tokens = out[0].tolist()
        raw = _token2str(tokens, self.tokenizer)
        return _post_process(raw)
