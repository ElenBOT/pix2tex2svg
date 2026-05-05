# ONNX Optimization Proposal (Scheme B)

This document outlines how the `pix2tex` model could be converted to ONNX to achieve extreme Docker image compression and faster inference on CPUs, without compromising OCR quality.

## Why ONNX?
Currently, `pix2tex` uses PyTorch. Even with the CPU-only version of PyTorch (Scheme A, currently implemented in this branch), the dependency still takes up around ~200MB. The original GPU PyTorch takes up ~3GB. 

By converting the model to ONNX, we can remove PyTorch entirely and use `onnxruntime`. This reduces the inference engine to less than 20MB and significantly speeds up CPU inference.

## The Challenge
`pix2tex` uses a custom Encoder-Decoder architecture with autoregressive beam search decoding. Because the decoder predicts tokens one-by-one based on previous tokens, it contains dynamic loops that are notoriously difficult to export natively via a single `torch.onnx.export` call.

## Implementation Steps (Future Work)

To fully implement Scheme B, the following code rewrite would be required:

1. **Split the Model**:
   - Export the Vision Encoder (ResNet/Swin) as `encoder.onnx`.
   - Export the Text Decoder (Transformer) as `decoder.onnx`.

2. **Rewrite the Inference Loop**:
   - Instead of calling `model(image)`, we rewrite the `server.py` to first run the image through `encoder.onnx` using `onnxruntime`.
   - Take the encoder's output features, and manually write a Python `while` loop that calls `decoder.onnx` repeatedly, feeding the previous output token until the `[EOS]` (End of Sentence) token is generated.

3. **Dependency Swap**:
   - Remove `torch` and `torchvision` from `requirements.txt`.
   - Add `onnxruntime`.

If you decide to proceed with this extreme optimization in the future, we will create a dedicated python script to handle the model splitting, and rewrite the OCR endpoint in `server.py` to use the ONNX runtime.
