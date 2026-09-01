from __future__ import annotations

from PIL import Image
from PIL.PngImagePlugin import PngInfo

from app.metadata import extract_image_metadata


def test_detects_embedded_ai_generation_hint(tmp_path):
    path = tmp_path / "generated.png"
    info = PngInfo()
    info.add_text("parameters", "Stable Diffusion prompt: cute goblin chibi")
    Image.new("RGB", (64, 64), "purple").save(path, pnginfo=info)

    metadata = extract_image_metadata(path)

    assert metadata["ai_generated_hint"] == 1
    assert "stable diffusion" in metadata["metadata_json"].lower()
