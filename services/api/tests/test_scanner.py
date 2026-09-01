from pathlib import Path

from PIL import Image

from app.db import connect, init_db
from app.scanner import scan_library


def test_scan_indexes_and_then_skips_unchanged_image(tmp_path: Path, monkeypatch):
    data_dir = tmp_path / "data"
    library = tmp_path / "library"
    library.mkdir()
    monkeypatch.setenv("GALEIRIA_DATA_DIR", str(data_dir))

    image_path = library / "reference.png"
    Image.new("RGB", (800, 600), "white").save(image_path)

    init_db()
    first = scan_library(str(library))
    second = scan_library(str(library))

    assert first == {"found": 1, "indexed": 1, "skipped": 0, "errors": 0}
    assert second == {"found": 1, "indexed": 0, "skipped": 1, "errors": 0}

    with connect() as conn:
        photo = conn.execute("SELECT * FROM photos").fetchone()

    assert photo is not None
    assert photo["filename"] == "reference.png"
    assert photo["width"] == 800
    assert photo["height"] == 600
    assert Path(photo["thumbnail_path"]).exists()
