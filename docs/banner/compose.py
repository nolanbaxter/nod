import sys
from PIL import Image, ImageDraw, ImageFont, ImageChops

src, out = sys.argv[1], sys.argv[2]
W, H = 1600, 560

box = Image.open(src).convert("RGB")
bg = box.getpixel((2, 2))
# crop the render to the model plus a margin
diff = ImageChops.difference(box, Image.new("RGB", box.size, bg)).convert("L").point(lambda v: 255 if v > 8 else 0)
l, t, r, b = diff.getbbox()
m = 30
box = box.crop((max(l - m, 0), max(t - m, 0), min(r + m, box.width), min(b + m, box.height)))
scale = (H - 40) / box.height
box = box.resize((int(box.width * scale), int(box.height * scale)), Image.LANCZOS)

img = Image.new("RGB", (W, H), bg)
img.paste(box, (W - box.width - 60, (H - box.height) // 2))

draw = ImageDraw.Draw(img)
font = ImageFont.truetype(r"C:\Windows\Fonts\CascadiaCode.ttf", 250)
font.set_variation_by_name("Bold")
x0, y0, x1, y1 = draw.textbbox((0, 0), "Nod", font=font)
draw.text((110 - x0, (H - (y1 - y0)) // 2 - y0), "Nod", font=font, fill=(34, 34, 34))
img.save(out, optimize=True)
print(out, img.size)
