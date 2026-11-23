"""Erzeugt das App-Icon (1024x1024, ohne Alpha-Kanal) für DriveDeck."""
import math
import sys
from PIL import Image, ImageDraw

S = 1024
SS = 4  # Supersampling
W = S * SS
img = Image.new("RGB", (W, W))
d = ImageDraw.Draw(img)

# Hintergrund: vertikaler Verlauf
top, bottom = (18, 24, 38), (6, 8, 14)
for y in range(W):
    t = y / W
    c = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
    d.line([(0, y), (W, y)], fill=c)

cx, cy = W / 2, W * 0.56
r = W * 0.36
start, end = 150, 390  # Grad, PIL: 0 = 3 Uhr, im Uhrzeigersinn

# Skala-Hintergrund
d.arc([cx - r, cy - r, cx + r, cy + r], start, end, fill=(40, 48, 66), width=int(W * 0.05))
# Aktiver Bereich: Verlauf Cyan -> Grün
steps = 120
active_end = start + (end - start) * 0.68
for i in range(steps):
    a0 = start + (active_end - start) * i / steps
    a1 = start + (active_end - start) * (i + 1) / steps + 0.5
    t = i / steps
    col = (int(0 + 60 * t), int(200 + 40 * t), int(255 - 120 * t))
    d.arc([cx - r, cy - r, cx + r, cy + r], a0, a1, fill=col, width=int(W * 0.05))

# Skalenstriche
for k in range(13):
    a = math.radians(start + (end - start) * k / 12)
    r1, r2 = r * 0.80, r * (0.70 if k % 3 == 0 else 0.75)
    d.line([(cx + r1 * math.cos(a), cy + r1 * math.sin(a)),
            (cx + r2 * math.cos(a), cy + r2 * math.sin(a))],
           fill=(200, 210, 225), width=int(W * (0.012 if k % 3 == 0 else 0.007)))

# Nadel
a = math.radians(active_end)
tip = (cx + r * 0.78 * math.cos(a), cy + r * 0.78 * math.sin(a))
perp = a + math.pi / 2
bw = W * 0.022
d.polygon([tip,
           (cx + bw * math.cos(perp), cy + bw * math.sin(perp)),
           (cx - bw * math.cos(perp), cy - bw * math.sin(perp))], fill=(255, 92, 70))
hub = W * 0.045
d.ellipse([cx - hub, cy - hub, cx + hub, cy + hub], fill=(235, 240, 248))

img = img.resize((S, S), Image.LANCZOS)
img.save(sys.argv[1] if len(sys.argv) > 1 else "AppIcon.png")
