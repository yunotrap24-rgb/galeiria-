from __future__ import annotations

import hashlib
from pathlib import Path
from typing import Callable, Iterable

from PIL import Image, ImageOps, UnidentifiedImageError

from .db import connect, data_dir
from .metadata import extract_image_metadata

SUPPORTED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp", ".gif", ".tif", ".tiff"}
THUMBNAIL_SIZE = (512, 512)
ProgressCallback = Callable[[dict[str, int]], None]


def iter_images(root: Path) -> Iterable[Path]:
    for path in root.rglob("*"):
        if path.is_file() and path.suffix.lower() in SUPPORTED_EXTENSIONS:
            yield path


def sha256_file(path: Path, chunk_size: int = 1024 * 1024) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while chunk := handle.read(chunk_size):
            digest.update(chunk)
    return digest.hexdigest()


def dhash_image(path: Path, hash_size: int = 8) -> str:
    """Return a 64-bit difference hash by default for near-duplicate candidates."""
    with Image.open(path) as image:
        image = ImageOps.exif_transpose(image).convert("L")
        image = image.resize((hash_size + 1, hash_size), Image.Resampling.LANCZOS)
        pixels = list(image.get_flattened_data())

    value = 0
    bit = 0
    width = hash_size + 1
    for y in range(hash_size):
        row = y * width
        for x in range(hash_size):
            if pixels[row + x] > pixels[row + x + 1]:
                value |= 1 << bit
            bit += 1
    return f"{value:0{hash_size * hash_size // 4}x}"


def make_thumbnail(source: Path, sha256: str) -> Path:
    folder = data_dir() / "thumbnails" / sha256[:2]
    folder.mkdir(parents=True, exist_ok=True)
    target = folder / f"{sha256}.jpg"
    if target.exists():
        return target

    with Image.open(source) as image:
        image = ImageOps.exif_transpose(image)
        image.thumbnail(THUMBNAIL_SIZE)
        if image.mode not in ("RGB", "L"):
            image = image.convert("RGB")
        image.save(target, "JPEG", quality=85, optimize=True)
    return target


def _register_library(root: Path) -> None:
    with connect() as conn:
        conn.execute(
            "INSERT INTO libraries(root) VALUES (?) ON CONFLICT(root) DO UPDATE SET enabled=1",
            (str(root),),
        )
        conn.commit()


def scan_library(root_value: str, progress: ProgressCallback | None = None) -> dict[str, int]:
    root = Path(root_value).expanduser().resolve()
    if not root.exists() or not root.is_dir():
        raise ValueError("A pasta da biblioteca não existe ou não é um diretório.")

    _register_library(root)
    stats = {"found": 0, "indexed": 0, "skipped": 0, "errors": 0}

    with connect() as conn:
        for path in iter_images(root):
            stats["found"] += 1
            try:
                file_stat = path.stat()
                current = conn.execute(
                    "SELECT id, size_bytes, modified_ns FROM photos WHERE path = ?",
                    (str(path),),
                ).fetchone()

                if current and current["size_bytes"] == file_stat.st_size and current["modified_ns"] == file_stat.st_mtime_ns:
                    stats["skipped"] += 1
                    if progress:
                        progress(stats.copy())
                    continue

                digest = sha256_file(path)
                perceptual_hash = dhash_image(path)
                metadata = extract_image_metadata(path)
                with Image.open(path) as image:
                    width, height = image.size
                    image_format = image.format

                thumbnail = make_thumbnail(path, digest)
                conn.execute(
                    """
                    INSERT INTO photos (
                        library_root, path, filename, sha256, perceptual_hash,
                        size_bytes, modified_ns, width, height, image_format, thumbnail_path,
                        metadata_json, captured_at, software, ai_generated_hint
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(path) DO UPDATE SET
                        library_root=excluded.library_root,
                        filename=excluded.filename,
                        sha256=excluded.sha256,
                        perceptual_hash=excluded.perceptual_hash,
                        size_bytes=excluded.size_bytes,
                        modified_ns=excluded.modified_ns,
                        width=excluded.width,
                        height=excluded.height,
                        image_format=excluded.image_format,
                        thumbnail_path=excluded.thumbnail_path,
                        metadata_json=excluded.metadata_json,
                        captured_at=excluded.captured_at,
                        software=excluded.software,
                        ai_generated_hint=excluded.ai_generated_hint,
                        indexed_at=CURRENT_TIMESTAMP
                    """,
                    (
                        str(root), str(path), path.name, digest, perceptual_hash,
                        file_stat.st_size, file_stat.st_mtime_ns, width, height,
                        image_format, str(thumbnail), metadata["metadata_json"],
                        metadata["captured_at"], metadata["software"], metadata["ai_generated_hint"],
                    ),
                )
                stats["indexed"] += 1
            except (OSError, UnidentifiedImageError, ValueError):
                stats["errors"] += 1

            if progress:
                progress(stats.copy())

        conn.execute(
            "UPDATE libraries SET last_scanned_at=CURRENT_TIMESTAMP WHERE root=?",
            (str(root),),
        )
        conn.commit()

    return stats
