#!/usr/bin/env python3
"""Draws ios/icons/icon-1024.png, the TOXCARD iOS app icon (1.1).

An aromatic ring (the toxin) drawn as a heavy white hexagon on deep antidote green, holding a
vermilion drop with a white cross: the poison and the response on one mark. Opaque RGB, as the
App Store requires. The web icon (icon.svg, icons/) is separate and unchanged. The PNG is
committed; run this only to change the drawing.
"""
import math, os
from PIL import Image, ImageDraw

IOS = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
S = 4
W = 1024 * S
TOP, BOT = (14, 122, 86), (5, 58, 42)          # antidote green, top to bottom
WHITE = (247, 250, 248)
VERMILION = (232, 84, 52)
RING_INNER = (9, 92, 65)

im = Image.new("RGB", (W, W), TOP)
d = ImageDraw.Draw(im)
for y in range(W):
    t = y / (W - 1)
    d.line([(0, y), (W, y)], fill=tuple(round(TOP[i] + (BOT[i] - TOP[i]) * t) for i in range(3)))

cx, cy = 512 * S, 520 * S

def hexagon(r, rot=90):
    return [(cx + r * math.cos(math.radians(rot + 60 * k)), cy + r * math.sin(math.radians(rot + 60 * k)))
            for k in range(6)]

def rounded_hex(r, corner, fill):
    # hexagon with softened corners: polygon inset plus a circle on each vertex
    pts = hexagon(r - corner * 1.15)
    d.polygon(pts, fill=fill)
    for i in range(6):
        a, b = pts[i], pts[(i + 1) % 6]
        d.line([a, b], fill=fill, width=int(corner * 2.3))
    for x, y in pts:
        d.ellipse([x - corner * 1.15, y - corner * 1.15, x + corner * 1.15, y + corner * 1.15], fill=fill)

rounded_hex(372 * S, 34 * S, WHITE)        # ring outer edge
rounded_hex(282 * S, 24 * S, RING_INNER)   # ring inner edge

# aromatic inner circle, as in a benzene ring, broken at the bottom for the drop
r = 196 * S
d.arc([cx - r, cy - r, cx + r, cy + r], start=125, end=55 + 360, fill=WHITE, width=26 * S)

# the drop: circle with a pointed top
dr = 112 * S
dcy = cy + 40 * S
d.ellipse([cx - dr, dcy - dr, cx + dr, dcy + dr], fill=VERMILION)
tip = (cx, dcy - dr * 2.05)
ang = math.radians(42)
left = (cx - dr * math.cos(ang), dcy - dr * math.sin(ang))
right = (cx + dr * math.cos(ang), dcy - dr * math.sin(ang))
d.polygon([tip, left, (cx, dcy), right], fill=VERMILION)

# white cross in the drop
arm, th = 62 * S, 26 * S
d.rounded_rectangle([cx - th, dcy - arm, cx + th, dcy + arm], radius=8 * S, fill=WHITE)
d.rounded_rectangle([cx - arm, dcy - th, cx + arm, dcy + th], radius=8 * S, fill=WHITE)

out = os.path.join(IOS, "icons", "icon-1024.png")
im.resize((1024, 1024), Image.LANCZOS).save(out)
print("wrote", out)
