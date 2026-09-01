from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

from app.db import init_db
from app.duplicates import exact_duplicate_groups, near_duplicate_pairs
from app.scanner import scan_library


def _make_test_image(path: Path, size=(320, 240), offset=0) -> None:
    image = Image.new("RGB", size, "white")
    draw = ImageDraw.Draw(image)
    draw.rectangle((20 + offset, 20, 160 + offset, 140), fill="black")
    draw.ellipse((180, 60, 260, 140), fill="gray")
    image.save(path)


def test_scan_skips_unchanged_file(tmp_path, monkeypatch):
    monkeypatch.setenv("GALEIRIA_DATA_DIR", str(tmp_path / "data"))
    library = tmp_path / "library"
    library.mkdir()
    _make_test_image(library / "piece.png")

    init_db()
    first = scan_library(str(library))
    second = scan_library(str(library))

    assert first == {"found": 1, "indexed": 1, "skipped": 0, "errors": 0}
    assert second == {"found": 1, "indexed": 0, "skipped": 1, "errors": 0}


def test_exact_duplicates_are_grouped(tmp_path, monkeypatch):
    monkeypatch.setenv("GALEIRIA_DATA_DIR", str(tmp_path / "data"))
    library = tmp_path / "library"
    library.mkdir()
    original = library / "a.png"
    copy = library / "b.png"
    _make_test_image(original)
    copy.write_bytes(original.read_bytes())

    init_db()
    scan_library(str(library))
    groups = exact_duplicate_groups()

    assert len(groups) == 1
    assert groups[0]["count"] == 2
    assert {p["filename"] for p in groups[0]["photos"]} == {"a.png", "b.png"}


def test_resized_image_is_near_duplicate_candidate(tmp_path, monkeypatch):
    monkeypatch.setenv("GALEIRIA_DATA_DIR", str(tmp_path / "data"))
    library = tmp_path / "library"
    library.mkdir()
    original = library / "original.png"
    resized = library / "resized.jpg"
    _make_test_image(original, size=(320, 240))
    with Image.open(original) as image:
        image.resize((640, 480)).save(resized, quality=90)

    init_db()
    scan_library(str(library))
    pairs = near_duplicate_pairs(max_distance=5)

    assert pairs
    assert {pairs[0]["left"]["filename"], pairs[0]["right"]["filename"]} == {"original.png", "resized.jpg"}
