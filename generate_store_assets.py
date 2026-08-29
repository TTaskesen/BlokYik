#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFont
import os

out_dir = "/Users/turguttaskesen/GodotProjects/BlokYik/google_play_assets"
os.makedirs(out_dir, exist_ok=True)

def get_font(size):
    for name in ["DejaVuSans-Bold.ttf", "Arial Bold.ttf"]:
        try:
            return ImageFont.truetype(name, size)
        except:
            pass
    return ImageFont.load_default()

# Feature graphic 1024x500
w, h = 1024, 500
img = Image.new("RGB", (w, h), (4,5,9))
draw = ImageDraw.Draw(img)

# Background gradient effect
for i in range(h):
    c = int(4 + (i/h)*30)
    draw.line([(0,i),(w,i)], fill=(c, c+5, 10))

# Title
font_title = get_font(86)
text = "BLOK YIK"
bbox = draw.textbbox((0,0), text, font=font_title)
tw = bbox[2]-bbox[0]
draw.text(((w-tw)//2, 120), text, fill=(241,55,77), font=font_title)

font_sub = get_font(34)
sub = "Godot 4 • Mobil • Masaüstü • Web"
bbox = draw.textbbox((0,0), sub, font=font_sub)
sw = bbox[2]-bbox[0]
draw.text(((w-sw)//2, 230), sub, fill=(165,176,225), font=font_sub)

# Decorative blocks
colors = [(66,140,191),(241,196,15),(231,76,60),(46,204,113)]
for i in range(6):
    x = 120 + i*140
    y = 320
    for j in range(3):
        draw.rectangle([x + j*28, y + j*28, x + j*28 + 24, y + j*28 + 24], fill=colors[i%4])

img.save(os.path.join(out_dir, "feature_graphic_1024x500.png"))

# App icon 512x512
ic = Image.new("RGB", (512,512), (54,61,82))
d = ImageDraw.Draw(ic)
# simple icon with block piece
draw.rounded_rectangle([10,10,502,502], radius=70, fill=(54,61,82), outline=(33,37,50), width=8)
# central block
c = 256
s = 120
for dx,dy in [(-s,-s), (0,-s), (s,-s), (-s,0), (0,0), (s,0)]:
    d.rectangle([c+dx, c+dy, c+dx+s, c+dy+s], fill=(66,140,191))
ic.save(os.path.join(out_dir, "app_icon_512x512.png"))

print("Assets created")
