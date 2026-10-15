#!/usr/bin/env python3
"""Generate Words app icons for Windows, macOS and desktop from our own SVG."""
from pathlib import Path
from PIL import Image
import io
import cairosvg

base = Path(__file__).resolve().parent
svg = base / "assets" / "words.svg"
out = base / "generated"
out.mkdir(parents=True, exist_ok=True)
src = Image.open(io.BytesIO(cairosvg.svg2png(url=str(svg), output_width=1024, output_height=1024))).convert("RGBA")
src.resize((512, 512), Image.Resampling.LANCZOS).save(out / "words-macos-512.png")
src.resize((256, 256), Image.Resampling.LANCZOS).save(out / "words-256.png")
src.save(out / "words.ico", format="ICO", sizes=[(16,16),(24,24),(32,32),(48,48),(64,64),(128,128),(256,256)])
src.save(out / "words.icns", format="ICNS")
print("Generated Words icons:", [f.name for f in out.iterdir()])
