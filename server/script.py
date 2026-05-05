import requests
import io
from PIL import Image

from main import palette


def closest_color(pixel: tuple[int, int, int]) -> tuple[int, int, int]:
    r, g, b = pixel
    return tuple(min(palette, key=lambda c: (r - c[0]) ** 2 + (g - c[1]) ** 2 + (b - c[2]) ** 2))  # type: ignore[return-value]


with open("image4.png", "rb") as f:
    b = f.read()

img = Image.open(io.BytesIO(b)).convert("RGB")
print(img.info)
if img.size != (64, 64):
    img = img.resize((64, 64), Image.LANCZOS)  # type: ignore
data = list(img.get_flattened_data())
new_data: list[tuple[int, int, int]] = []
for _d in data:
    d: tuple[int, int, int] = _d  # type: ignore
    found = False
    for c in palette:
        if d[0] == c[0] and d[1] == c[1] and d[2] == c[2]:
            found = True
            break
    if not found:
        d = closest_color(d)
    new_data.append(d)

new_img = Image.new("RGB", img.size)
new_img.putdata(new_data)  # type: ignore
print(new_img.info)

buf = io.BytesIO()
new_img.save(buf, format="PNG")
b = buf.getvalue()

resp = requests.post("https://stonesoup.uk/images", b)
print(resp)
