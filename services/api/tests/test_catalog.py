from __future__ import annotations

from PIL import Image

from app.catalog import (
    add_photo_to_project,
    assign_tag,
    create_project,
    create_tag,
    project_detail,
    search_photos,
)
from app.db import connect, init_db
from app.scanner import scan_library


def test_tags_projects_and_search(tmp_path, monkeypatch):
    monkeypatch.setenv("GALEIRIA_DATA_DIR", str(tmp_path / "data"))
    library = tmp_path / "library"
    library.mkdir()
    Image.new("RGB", (200, 200), "green").save(library / "goblin-reference.png")

    init_db()
    scan_library(str(library))
    with connect() as conn:
        photo_id = conn.execute("SELECT id FROM photos").fetchone()["id"]

    tag = create_tag("goblin")
    assign_tag(photo_id, tag["id"])
    project = create_project("Goblin Chibi", "Boneco para impressão 3D")
    add_photo_to_project(project["id"], photo_id, "reference")

    detail = project_detail(project["id"])
    assert detail is not None
    assert detail["photos"][0]["stage"] == "reference"
    assert search_photos("goblin")
    assert search_photos("Chibi")
