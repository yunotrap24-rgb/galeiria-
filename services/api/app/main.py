from __future__ import annotations

from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel

from .db import connect, init_db
from .scanner import scan_library

app = FastAPI(title="Galeiria API", version="0.1.0")


class ScanRequest(BaseModel):
    path: str


@app.on_event("startup")
def startup() -> None:
    init_db()


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/api/v1/libraries/scan")
def scan(request: ScanRequest) -> dict[str, int]:
    try:
        return scan_library(request.path)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@app.get("/api/v1/photos")
def photos(limit: int = 100, offset: int = 0) -> list[dict]:
    limit = max(1, min(limit, 500))
    offset = max(0, offset)
    with connect() as conn:
        rows = conn.execute(
            """
            SELECT id, filename, sha256, size_bytes, width, height,
                   image_format, indexed_at
            FROM photos
            ORDER BY id DESC
            LIMIT ? OFFSET ?
            """,
            (limit, offset),
        ).fetchall()
    return [dict(row) for row in rows]


@app.get("/api/v1/photos/{photo_id}/thumbnail")
def thumbnail(photo_id: int) -> FileResponse:
    with connect() as conn:
        row = conn.execute(
            "SELECT thumbnail_path FROM photos WHERE id = ?",
            (photo_id,),
        ).fetchone()

    if not row:
        raise HTTPException(status_code=404, detail="Imagem não encontrada.")

    path = Path(row["thumbnail_path"])
    if not path.exists():
        raise HTTPException(status_code=404, detail="Thumbnail não encontrado.")

    return FileResponse(path, media_type="image/jpeg")
