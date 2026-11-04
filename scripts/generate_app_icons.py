"""Regenerate platform launcher icons. Requires Pillow: python -m pip install Pillow."""
import json
import shutil
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/branding/velora-app-icon.png"


def generate():
    image = Image.open(SOURCE).convert("RGB")
    # Adaptive icons use a navy background instead of the launcher's legacy backing.
    artwork = ROOT / "android/app/src/main/res/drawable-nodpi/ic_launcher_artwork.png"
    artwork.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(SOURCE, artwork)
    outputs = {}
    for density, size in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        outputs[f"android/app/src/main/res/mipmap-{density}/ic_launcher.png"] = size
    for platform in ("ios", "macos"):
        folder = f"{platform}/Runner/Assets.xcassets/AppIcon.appiconset"
        manifest = json.loads((ROOT / folder / "Contents.json").read_text())
        for entry in manifest["images"]:
            outputs[f"{folder}/{entry['filename']}"] = round(float(entry["size"].split("x")[0]) * float(entry["scale"].removesuffix("x")))
    outputs["web/favicon.png"] = 32
    for size in (192, 512):
        for name in ("Icon", "Icon-maskable"):
            outputs[f"web/icons/{name}-{size}.png"] = size
    for name, size in outputs.items():
        target = ROOT / name
        target.parent.mkdir(parents=True, exist_ok=True)
        image.resize((size, size), Image.Resampling.LANCZOS).save(target)
    ico = ROOT / "windows/runner/resources/app_icon.ico"
    image.resize((256, 256), Image.Resampling.LANCZOS).save(ico, sizes=[(s, s) for s in (16, 24, 32, 48, 64, 128, 256)])
    for name, size in outputs.items():
        with Image.open(ROOT / name) as result:
            assert result.size == (size, size), name
            assert result.mode == "RGB", name
    with Image.open(ico) as result:
        assert result.format == "ICO"
    print(f"Generated and verified {len(outputs)} PNG icons and Windows ICO.")


if __name__ == "__main__":
    generate()
