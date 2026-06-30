"""Shrink the mascot WebPs and knock out the white background to transparent.

- Resizes 1080x1920 -> width 420 (smooth + small).
- Flood-fills white from the borders only, so the character's interior whites
  (eyes, teeth) are preserved; only the connected background is removed.
Run from project root:  python video/process_mascot.py
"""
import os
import sys
from PIL import Image, ImageDraw
import numpy as np

SRC = "assets/mom"
W = 420
SENT = (255, 0, 255)
ALL = ["idle", "celebrate", "shh", "diaper", "surprised",
       "pointing", "calm", "hug", "tired"]
NAMES = sys.argv[1:] if len(sys.argv) > 1 else ALL


def whiteish(px):
    return px[0] > 230 and px[1] > 230 and px[2] > 230


for name in NAMES:
    path = os.path.join(SRC, name + ".webp")
    im = Image.open(path)
    n = getattr(im, "n_frames", 1)
    frames, durations = [], []
    h = W
    for i in range(n):
        im.seek(i)
        dur = im.info.get("duration", 40)
        fr = im.convert("RGB")
        h = int(round(fr.height * (W / fr.width)))
        if h % 2:
            h += 1
        fr = fr.resize((W, h), Image.LANCZOS)
        work = fr.copy()
        for xy in [(0, 0), (W - 1, 0), (0, h - 1), (W - 1, h - 1),
                   (W // 2, 0), (W // 2, h - 1)]:
            if whiteish(work.getpixel(xy)):
                ImageDraw.floodfill(work, xy, SENT, thresh=42)
        arr = np.array(fr)
        warr = np.array(work)
        bg = np.all(warr == np.array(SENT), axis=-1)
        alpha = np.where(bg, 0, 255).astype("uint8")
        rgba = np.dstack([arr, alpha])
        frames.append(Image.fromarray(rgba, "RGBA"))
        durations.append(dur)
    frames[0].save(path, format="WEBP", save_all=True,
                   append_images=frames[1:], duration=durations, loop=0,
                   quality=82, method=4)
    kb = os.path.getsize(path) // 1024
    print(f"{name}: {W}x{h}, {n} frames, {kb} KB -> transparent")
