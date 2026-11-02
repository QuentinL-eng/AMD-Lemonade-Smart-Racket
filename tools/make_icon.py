#!/usr/bin/env python3
"""Writes the Tennis Buddee app icon into the iOS/Mac and Watch asset catalogs, the website and docs.

    python3 tools/make_icon.py

Artwork: the square-cornered icon from marketing/tennis-buddee-logo (cream "b" racket, optic-yellow ball on court green).
"""
import json
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(ROOT, "marketing/tennis-buddee-logo/png/tennis-buddee-icon-square-1024x1024.png")
N = 1024


def mac_icon(art):
    """macOS icons aren't masked by the system: rounded square with margin and shadow."""
    canvas = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    inset = int(N * 0.098)
    size = N - 2 * inset
    tile = art.resize((size, size), Image.LANCZOS)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size, size], radius=int(size * 0.225), fill=255)
    shadow = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([inset, inset + N * 0.012, inset + size, inset + size + N * 0.012],
                                             radius=int(size * 0.225), fill=(0, 0, 0, 90))
    canvas = Image.alpha_composite(canvas, shadow.filter(ImageFilter.GaussianBlur(N * 0.012)))
    canvas.paste(tile, (inset, inset), mask)
    return canvas


def main():
    art = Image.open(SOURCE).convert("RGBA")
    final = art.convert("RGB")
    mac = mac_icon(art)

    shared = os.path.join(ROOT, "apple/Shared/Assets.xcassets/AppIcon.appiconset")
    watch = os.path.join(ROOT, "apple/Watch/Assets.xcassets/AppIcon.appiconset")
    final.save(os.path.join(shared, "icon-1024.png"))
    final.save(os.path.join(watch, "icon-1024.png"))
    images = [{"idiom": "universal", "platform": "ios", "size": "1024x1024", "filename": "icon-1024.png"}]
    for pt in (16, 32, 128, 256, 512):
        for scale in (1, 2):
            name = f"mac-{pt}@{scale}x.png"
            mac.resize((pt * scale, pt * scale), Image.LANCZOS).save(os.path.join(shared, name))
            images.append({"idiom": "mac", "scale": f"{scale}x", "size": f"{pt}x{pt}", "filename": name})
    json.dump({"images": images, "info": {"author": "xcode", "version": 1}},
              open(os.path.join(shared, "Contents.json"), "w"), indent=2)
    json.dump({"images": [{"idiom": "universal", "platform": "watchos", "size": "1024x1024", "filename": "icon-1024.png"}],
               "info": {"author": "xcode", "version": 1}}, open(os.path.join(watch, "Contents.json"), "w"), indent=2)
    final.save(os.path.join(ROOT, "docs/icon.png"))
    final.resize((128, 128), Image.LANCZOS).save(os.path.join(ROOT, "website/img/icon.png"))
    print("icons written")


if __name__ == "__main__":
    main()
