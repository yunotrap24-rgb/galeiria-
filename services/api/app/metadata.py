from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from PIL import ExifTags, Image, ImageOps

AI_HINTS = (
    "stable diffusion",
    "automatic1111",
    "a1111",
    "comfyui",
    "midjourney",
    "dall-e",
    "dalle",
    "fooocus",
    "novelai",
    "invokeai",
    "generative ai",
)


def _json_safe(value: Any) -> Any:
    if value is None or isinstance(value, (str, int, float, bool)):
        return value
    if isinstance(value, bytes):
        return value[:256].hex()
    if isinstance(value, (list, tuple)):
        return [_json_safe(item) for item in value[:100]]
    if isinstance(value, dict):
        return {str(key): _json_safe(item) for key, item in list(value.items())[:200]}
    return str(value)


def extract_image_metadata(path: Path) -> dict[str, Any]:
    with Image.open(path) as raw:
        image = ImageOps.exif_transpose(raw)
        exif_data: dict[str, Any] = {}
        try:
            exif = image.getexif()
            for tag_id, value in exif.items():
                name = ExifTags.TAGS.get(tag_id, str(tag_id))
                exif_data[name] = _json_safe(value)
        except (AttributeError, TypeError, ValueError):
            pass

        embedded: dict[str, Any] = {}
        for key, value in raw.info.items():
            if key.lower() in {"icc_profile", "exif"}:
                continue
            embedded[str(key)] = _json_safe(value)

    combined_text = " ".join(
        str(value) for value in [*exif_data.values(), *embedded.values()] if value is not None
    ).lower()
    matched_hints = [hint for hint in AI_HINTS if hint in combined_text]

    captured_at = (
        exif_data.get("DateTimeOriginal")
        or exif_data.get("DateTimeDigitized")
        or exif_data.get("DateTime")
    )
    software = exif_data.get("Software") or embedded.get("Software") or embedded.get("software")

    payload = {
        "exif": exif_data,
        "embedded": embedded,
        "ai_hints": matched_hints,
    }
    return {
        "metadata_json": json.dumps(payload, ensure_ascii=False, separators=(",", ":")),
        "captured_at": str(captured_at) if captured_at else None,
        "software": str(software) if software else None,
        "ai_generated_hint": 1 if matched_hints else 0,
    }
