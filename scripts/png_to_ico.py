"""Convert docs/static/NotionIcon.png to NotionIcon.ico (multi-size)."""
from PIL import Image
import os, pathlib

ROOT = pathlib.Path(__file__).parent.parent
SRC  = ROOT / "docs" / "static" / "NotionIcon.png"
DST  = ROOT / "NotionIcon.ico"

img = Image.open(SRC).convert("RGBA")
print(f"Source: {SRC} ({img.size[0]}x{img.size[1]})")
img.save(str(DST), format="ICO", sizes=[(16, 16), (32, 32), (48, 48), (256, 256)])
print(f"Saved:  {DST} ({os.path.getsize(DST)} bytes)")
