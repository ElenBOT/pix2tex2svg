import io, base64, json
import urllib.request
from PIL import Image, ImageDraw

# Create test image
img = Image.new('RGB', (200, 60), 'white')
draw = ImageDraw.Draw(img)
draw.text((10, 15), 'x + y = z', fill='black')
buf = io.BytesIO()
img.save(buf, format='PNG')
b64 = "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()

payload = json.dumps({"image": b64}).encode()
req = urllib.request.Request(
    "http://localhost:7071/ocr/base64",
    data=payload,
    headers={"Content-Type": "application/json"},
    method="POST"
)
with urllib.request.urlopen(req) as resp:
    result = json.loads(resp.read())
print("Result:", result)
