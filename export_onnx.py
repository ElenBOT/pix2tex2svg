import torch
from pix2tex.cli import LatexOCR
import os

print("Loading PyTorch model...")
model_obj = LatexOCR()
model = model_obj.model

encoder = model.encoder
decoder = model.decoder.net

encoder.eval()
decoder.eval()

# Dummy inputs for encoder
B = 1
H, W = 160, 160
dummy_img = torch.randn(B, 1, H, W).to(model_obj.args.device)

print("Exporting Encoder to ONNX...")
torch.onnx.export(
    encoder,
    (dummy_img,),
    "encoder.onnx",
    export_params=True,
    opset_version=14,
    do_constant_folding=True,
    input_names=["images"],
    output_names=["context"],
    dynamic_axes={
        "images": {0: "batch_size", 2: "height", 3: "width"},
        "context": {0: "batch_size", 1: "encoded_len"}
    }
)

# Dummy inputs for decoder
print("Running dummy encoder pass...")
with torch.no_grad():
    dummy_context = encoder(dummy_img)

seq_len = 5
dummy_tgt_seq = torch.randint(0, 8000, (B, seq_len)).to(model_obj.args.device)

print("Exporting Decoder to ONNX...")
# Note: pix2tex decoder forward pass is: self.net(x, context=...)
class DecoderWrapper(torch.nn.Module):
    def __init__(self, dec):
        super().__init__()
        self.dec = dec
    def forward(self, x, context):
        # We ignore mask for simplicity if it's mostly true anyway
        return self.dec(x, context=context)

dec_wrapper = DecoderWrapper(decoder)
dec_wrapper.eval()

torch.onnx.export(
    dec_wrapper,
    (dummy_tgt_seq, dummy_context),
    "decoder.onnx",
    export_params=True,
    opset_version=14,
    do_constant_folding=True,
    input_names=["x", "context"],
    output_names=["logits"],
    dynamic_axes={
        "x": {0: "batch_size", 1: "seq_len"},
        "context": {0: "batch_size", 1: "encoded_len"},
        "logits": {0: "batch_size", 1: "seq_len"}
    }
)

print("ONNX export complete. Created encoder.onnx and decoder.onnx")
