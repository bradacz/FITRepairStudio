#!/usr/bin/env python3
from pathlib import Path
from PIL import Image
import struct
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Assets" / "AppIcon-source.png"
PREVIEW = ROOT / "Assets" / "AppIcon.png"
ICONSET = ROOT / "Assets" / "AppIcon.iconset"
ICNS = ROOT / "Assets" / "AppIcon.icns"

SIZES = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

ICNS_CHUNKS = [
    ("icp4", "icon_16x16.png"),
    ("icp5", "icon_32x32.png"),
    ("icp6", "icon_32x32@2x.png"),
    ("ic07", "icon_128x128.png"),
    ("ic08", "icon_256x256.png"),
    ("ic09", "icon_512x512.png"),
    ("ic10", "icon_512x512@2x.png"),
    ("ic11", "icon_16x16@2x.png"),
    ("ic12", "icon_32x32@2x.png"),
    ("ic13", "icon_128x128@2x.png"),
    ("ic14", "icon_256x256@2x.png"),
]


def square_crop(image):
    side = min(image.size)
    left = (image.width - side) // 2
    top = (image.height - side) // 2
    return image.crop((left, top, left + side, top + side))


def save_png(image, path, size):
    resized = image.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(path, "PNG")


def write_icns(iconset, output):
    chunks = []
    for chunk_type, filename in ICNS_CHUNKS:
        png = (iconset / filename).read_bytes()
        chunks.append(chunk_type.encode("ascii") + struct.pack(">I", len(png) + 8) + png)
    payload = b"".join(chunks)
    output.write_bytes(b"icns" + struct.pack(">I", len(payload) + 8) + payload)


def main():
    if not SOURCE.exists():
        print(f"missing source icon: {SOURCE}", file=sys.stderr)
        return 1

    ICONSET.mkdir(parents=True, exist_ok=True)
    image = square_crop(Image.open(SOURCE)).convert("RGBA")
    save_png(image, PREVIEW, 1024)
    for filename, size in SIZES:
        save_png(image, ICONSET / filename, size)

    result = subprocess.run(
        ["iconutil", "--convert", "icns", "--output", str(ICNS), str(ICONSET)],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    if result.returncode != 0:
        write_icns(ICONSET, ICNS)
    print(ICNS)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
