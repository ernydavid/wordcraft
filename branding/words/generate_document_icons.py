#!/usr/bin/env python3
"""Generate Words document icons from the provided Figma SVG master."""
from pathlib import Path
from xml.etree import ElementTree as ET
import io
import cairosvg
from PIL import Image

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "assets" / "words-document-base.svg"
OUTPUT = ROOT / "generated" / "documents"
EXTENSIONS = ("docx", "doc", "docm", "dotx", "dotm", "dot", "rtf", "odt", "txt", "md", "html", "htm")

def main():
    source = SOURCE.read_text(encoding="utf-8")
    ET.fromstring(source)
    if source.count("</svg>") != 1:
        raise ValueError("Expected one closing SVG element")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for ext in EXTENSIONS:
        label = (
            f'<text x="674" y="796" fill="#152F63" font-family="DejaVu Sans, Arial, sans-serif" '
            f'font-size="{107 if len(ext) <= 4 else 94}" font-weight="bold" text-anchor="middle" '
            f'dominant-baseline="middle" letter-spacing="-1">{ext.upper()}</text>'
        )
        svg = source.replace("</svg>", label + "</svg>").encode("utf-8")
        stem = OUTPUT / ("words-" + ext)
        stem.with_suffix(".svg").write_bytes(svg)
        png = cairosvg.svg2png(bytestring=svg, output_width=1024, output_height=1024)
        image = Image.open(io.BytesIO(png)).convert("RGBA")
        image.save(stem.with_suffix(".png"))
        image.save(stem.with_suffix(".ico"), format="ICO", sizes=[(16,16),(24,24),(32,32),(48,48),(64,64),(128,128),(256,256)])
        image.save(stem.with_suffix(".icns"), format="ICNS")
    print(f"Generated {len(EXTENSIONS)} Words document icons")

if __name__ == "__main__":
    main()
