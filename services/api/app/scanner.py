from __future__ import annotations

import hashlib
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageOps, UnidentifiedImageError

from .db import connect, data_dir

SUPPORTED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp", ".gif", ".tif", ".tiff"}
THUMBNAIL_SIZE = (512, 512)


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


def scan_library(root_value: str) -> dict[str, int]:
    root = Path(root_value).expanduser().resolve()
    if not root.exists() or not root.is_dir():
        raise ValueError("A pasta da biblioteca não existe ou não é um diretório.")

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
                    continue

                digest = sha256_file(path)
                with Image.open(path) as image:
                    width, height = image.size
                    image_format = image.format

                thumbnail = make_thumbnail(path, digest)
                conn.execute(
                    """
                    INSERT INTO photos (
                        library_root, path, filename, sha256, size_bytes,
                        modified_ns, width, height, image_format, thumbnail_path
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(path) DO UPDATE SET
                        library_root=excluded.library_root,
                        filename=excluded.filename,
                        sha256=excluded.sha256,
                        size_bytes=excluded.size_bytes,
                        modified_ns=excluded.modified_ns,
                        width=excluded.width,
                        height=excluded.height,
                        image_format=excluded.image_format,
                        thumbnail_path=excluded.thumbnail_path,
                        indexed_at=CURRENT_TIMESTAMP
                    """,
                    (
                        str(root), str(path), path.name, digest, file_stat.st_size,
                        file_stat.st_mtime_ns, width, height, image_format, str(thumbnail),
                    ),
                )
                stats["indexed"] += 1
            except (OSError, UnidentifiedImageError, ValueError):
                stats["errors"] += 1

        conn.commit()

    return stats
