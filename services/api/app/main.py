from __future__ import annotations

import mimetypes
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel

from .db import connect, init_db
from .duplicates import exact_duplicate_groups, near_duplicate_pairs
from .jobs import create_scan_job, get_scan_job
from .scanner import scan_library

app = FastAPI(title="Galeiria API", version="0.2.0")


class ScanRequest(BaseModel):
    path: str


@app.on_event("startup")
def startup() -> None:
    init_db()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "version": "0.2.0"}


@app.get("/api/v1/stats")
def stats() -> dict[str, int]:
    with connect() as conn:
        photos = conn.execute("SELECT COUNT(*) AS value FROM photos").fetchone()["value"]
        libraries = conn.execute("SELECT COUNT(*) AS value FROM libraries WHERE enabled=1").fetchone()["value"]
        exact_groups = conn.execute(
            "SELECT COUNT(*) AS value FROM (SELECT sha256 FROM photos GROUP BY sha256 HAVING COUNT(*)>1)"
        ).fetchone()["value"]
    return {"photos": photos, "libraries": libraries, "exact_duplicate_groups": exact_groups}


@app.get("/api/v1/libraries")
def libraries() -> list[dict]:
    with connect() as conn:
        rows = conn.execute("SELECT * FROM libraries ORDER BY id ASC").fetchall()
    return [dict(row) for row in rows]


@app.post("/api/v1/libraries/scan")
def scan(request: ScanRequest) -> dict[str, int]:
    """Synchronous compatibility endpoint useful for CLI/tests."""
    try:
        return scan_library(request.path)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@app.post("/api/v1/scan-jobs", status_code=202)
def start_scan_job(request: ScanRequest) -> dict[str, int | str]:
    try:
        job_id = create_scan_job(request.path)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return {"id": job_id, "status": "queued"}


@app.get("/api/v1/scan-jobs/{job_id}")
def scan_job(job_id: int) -> dict:
    job = get_scan_job(job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job não encontrado.")
    return job


@app.get("/api/v1/photos")
def photos(limit: int = 100, offset: int = 0) -> list[dict]:
    limit = max(1, min(limit, 500))
    offset = max(0, offset)
    with connect() as conn:
        rows = conn.execute(
            """
            SELECT id, filename, sha256, perceptual_hash, size_bytes, width, height,
                   image_format, indexed_at
            FROM photos
            ORDER BY id DESC
            LIMIT ? OFFSET ?
            """,
            (limit, offset),
        ).fetchall()
    return [dict(row) for row in rows]


@app.get("/api/v1/photos/{photo_id}")
def photo_detail(photo_id: int) -> dict:
    with connect() as conn:
        row = conn.execute(
            """
            SELECT id, library_root, path, filename, sha256, perceptual_hash,
                   size_bytes, modified_ns, width, height, image_format, indexed_at
            FROM photos WHERE id=?
            """,
            (photo_id,),
        ).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Imagem não encontrada.")
    return dict(row)


@app.get("/api/v1/photos/{photo_id}/thumbnail")
def thumbnail(photo_id: int) -> FileResponse:
    with connect() as conn:
        row = conn.execute("SELECT thumbnail_path FROM photos WHERE id=?", (photo_id,)).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Imagem não encontrada.")
    path = Path(row["thumbnail_path"])
    if not path.exists():
        raise HTTPException(status_code=404, detail="Thumbnail não encontrado.")
    return FileResponse(path, media_type="image/jpeg")


@app.get("/api/v1/photos/{photo_id}/file")
def original_file(photo_id: int) -> FileResponse:
    with connect() as conn:
        row = conn.execute("SELECT path FROM photos WHERE id=?", (photo_id,)).fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Imagem não encontrada.")
    path = Path(row["path"])
    if not path.exists():
        raise HTTPException(status_code=404, detail="Arquivo original não encontrado.")
    media_type = mimetypes.guess_type(path.name)[0] or "application/octet-stream"
    return FileResponse(path, media_type=media_type, filename=path.name)


@app.get("/api/v1/duplicates/exact")
def exact_duplicates(limit: int = 100) -> list[dict]:
    return exact_duplicate_groups(limit=limit)


@app.get("/api/v1/duplicates/near")
def near_duplicates(max_distance: int = 5, limit: int = 200) -> list[dict]:
    return near_duplicate_pairs(max_distance=max_distance, limit=limit)
