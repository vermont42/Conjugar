"""Recolor Josh's navy suit in familia-gpt-2 to the matador's royal blue.

Pixel-only (no generative re-render), so faces are untouched: every pixel
outside the feathered suit mask is byte-identical to the source.
Usage: python3 recolor_suit.py art-sources/end-scene/familia-gpt-2.png art-sources/end-scene/familia-gpt-2-royal.png 1.5
"""
import sys
from PIL import Image, ImageFilter
import numpy as np

src, out, gain = sys.argv[1], sys.argv[2], float(sys.argv[3])
TARGET_HUE = 0.612  # median hue of the matador's jacket in toreros-gpt-1

im = Image.open(src).convert("RGB")
W, H = im.size
s = W / 1600.0  # spatial limits below are in 1600-wide preview coordinates
rgb = np.asarray(im).astype(np.float32)
hsv = np.asarray(im.convert("HSV")).astype(np.float32) / 255.0
h, sat, v = hsv[..., 0], hsv[..., 1], hsv[..., 2]

def ramp(x, a, b):
    t = np.clip((x - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)

# 1. Seed: blue-to-purple fabric pixels.
seed = (1 - ramp(np.abs(h - 0.66), 0.10, 0.14)) * ramp(sat, 0.10, 0.25)
# 2. Close small holes (dark reddish specks inside the fabric), then feather.
m = Image.fromarray((seed * 255).astype(np.uint8))
m = m.filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.MinFilter(9)).filter(ImageFilter.GaussianBlur(2))
closed = np.asarray(m).astype(np.float32) / 255.0
# 3. Guards: lit non-blue pixels (skin, gold tie, shirt) stay as they are.
blueish = 1 - ramp(np.abs(h - 0.66), 0.14, 0.18)
guard = 1 - ramp(v, 0.30, 0.40) * (1 - blueish)
guard *= 1 - ramp(v, 0.55, 0.65) * (1 - ramp(sat, 0.15, 0.25))  # white shirt in shadow
yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
space = ramp(xx, 880 * s, 960 * s) * ramp(yy, 330 * s, 380 * s)  # below the eyes
w = np.clip(closed * guard * space, 0, 1)

# Fully recolored version: royal-blue hue with a little of the original variation.
in_range = np.abs(h - 0.66) < 0.15
h_full = np.where(in_range, TARGET_HUE + 0.3 * (h - 0.64), TARGET_HUE)
s_full = np.clip(np.maximum(sat, 0.35) * 1.10, 0, 1)
v_full = np.clip((v ** 0.85) * gain, 0, 1)
full = np.asarray(Image.fromarray(
    (np.stack([h_full % 1.0, s_full, v_full], -1) * 255 + 0.5).astype(np.uint8), "HSV"
).convert("RGB")).astype(np.float32)

res = rgb * (1 - w[..., None]) + full * w[..., None]
res = np.where(w[..., None] > 0, res + 0.5, rgb).astype(np.uint8)
Image.fromarray(res).save(out)
Image.fromarray((w * 255).astype(np.uint8)).resize((1600, round(1600 * H / W))).save(out.rsplit(".", 1)[0] + "-mask.png")
print("changed pixels:", int((w > 0).sum()), "of", W * H)
