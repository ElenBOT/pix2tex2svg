import torch
from pix2tex.cli import LatexOCR
import os

model_obj = LatexOCR()

resizer = model_obj.image_resizer
if resizer is not None:
    resizer.eval()
    dummy_input = torch.randn(1, 1, 160, 160).to(model_obj.args.device)
    print("Exporting Resizer to ONNX...")
    torch.onnx.export(
        resizer,
        (dummy_input,),
        "image_resizer.onnx",
        export_params=True,
        opset_version=14,
        do_constant_folding=True,
        input_names=["input"],
        output_names=["output"],
        dynamic_axes={
            "input": {0: "batch_size", 2: "height", 3: "width"},
            "output": {0: "batch_size"}
        }
    )
    print("Exported image_resizer.onnx")
else:
    print("No image resizer found.")
