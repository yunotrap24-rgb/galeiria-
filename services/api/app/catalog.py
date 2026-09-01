from __future__ import annotations

import sqlite3

from .db import connect


def list_tags() -> list[dict]:
    with connect() as conn:
        rows = conn.execute(
            """
            SELECT t.id, t.name, t.created_at, COUNT(pt.photo_id) AS photo_count
            FROM tags t
            LEFT JOIN photo_tags pt ON pt.tag_id=t.id
            GROUP BY t.id
            ORDER BY t.name COLLATE NOCASE
            """
        ).fetchall()
    return [dict(row) for row in rows]


def create_tag(name: str) -> dict:
    clean = name.strip()
    if not clean:
        raise ValueError("O nome da tag não pode ser vazio.")
    try:
        with connect() as conn:
            cursor = conn.execute("INSERT INTO tags(name) VALUES (?)", (clean,))
            tag_id = int(cursor.lastrowid)
            row = conn.execute("SELECT * FROM tags WHERE id=?", (tag_id,)).fetchone()
            conn.commit()
    except sqlite3.IntegrityError as exc:
        raise ValueError("Essa tag já existe.") from exc
    return dict(row)


def assign_tag(photo_id: int, tag_id: int, source: str = "user", confidence: float | None = None) -> None:
    with connect() as conn:
        if not conn.execute("SELECT 1 FROM photos WHERE id=?", (photo_id,)).fetchone():
            raise LookupError("Imagem não encontrada.")
        if not conn.execute("SELECT 1 FROM tags WHERE id=?", (tag_id,)).fetchone():
            raise LookupError("Tag não encontrada.")
        conn.execute(
            """
            INSERT INTO photo_tags(photo_id, tag_id, source, confidence)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(photo_id, tag_id) DO UPDATE SET source=excluded.source, confidence=excluded.confidence
            """,
            (photo_id, tag_id, source, confidence),
        )
        conn.commit()


def list_projects() -> list[dict]:
    with connect() as conn:
        rows = conn.execute(
            """
            SELECT p.id, p.name, p.description, p.created_at, p.updated_at,
                   COUNT(pp.photo_id) AS photo_count
            FROM projects p
            LEFT JOIN project_photos pp ON pp.project_id=p.id
            GROUP BY p.id
            ORDER BY p.updated_at DESC, p.name COLLATE NOCASE
            """
        ).fetchall()
    return [dict(row) for row in rows]


def create_project(name: str, description: str = "") -> dict:
    clean = name.strip()
    if not clean:
        raise ValueError("O nome do projeto não pode ser vazio.")
    try:
        with connect() as conn:
            cursor = conn.execute(
                "INSERT INTO projects(name, description) VALUES (?, ?)",
                (clean, description.strip()),
            )
            project_id = int(cursor.lastrowid)
            row = conn.execute("SELECT * FROM projects WHERE id=?", (project_id,)).fetchone()
            conn.commit()
    except sqlite3.IntegrityError as exc:
        raise ValueError("Esse projeto já existe.") from exc
    return dict(row)


def add_photo_to_project(project_id: int, photo_id: int, stage: str = "reference") -> None:
    stage = stage.strip() or "reference"
    with connect() as conn:
        if not conn.execute("SELECT 1 FROM projects WHERE id=?", (project_id,)).fetchone():
            raise LookupError("Projeto não encontrado.")
        if not conn.execute("SELECT 1 FROM photos WHERE id=?", (photo_id,)).fetchone():
            raise LookupError("Imagem não encontrada.")
        conn.execute(
            """
            INSERT INTO project_photos(project_id, photo_id, stage)
            VALUES (?, ?, ?)
            ON CONFLICT(project_id, photo_id) DO UPDATE SET stage=excluded.stage
            """,
            (project_id, photo_id, stage),
        )
        conn.execute("UPDATE projects SET updated_at=CURRENT_TIMESTAMP WHERE id=?", (project_id,))
        conn.commit()


def project_detail(project_id: int) -> dict | None:
    with connect() as conn:
        project = conn.execute("SELECT * FROM projects WHERE id=?", (project_id,)).fetchone()
        if not project:
            return None
        photos = conn.execute(
            """
            SELECT ph.id, ph.filename, ph.width, ph.height, ph.image_format, pp.stage
            FROM project_photos pp
            JOIN photos ph ON ph.id=pp.photo_id
            WHERE pp.project_id=?
            ORDER BY pp.created_at DESC
            """,
            (project_id,),
        ).fetchall()
    result = dict(project)
    result["photos"] = [dict(row) for row in photos]
    return result


def search_photos(query: str, limit: int = 100) -> list[dict]:
    term = query.strip()
    if not term:
        return []
    pattern = f"%{term}%"
    limit = max(1, min(limit, 500))
    with connect() as conn:
        rows = conn.execute(
            """
            SELECT DISTINCT ph.id, ph.filename, ph.sha256, ph.width, ph.height, ph.image_format, ph.indexed_at
            FROM photos ph
            LEFT JOIN photo_tags pt ON pt.photo_id=ph.id
            LEFT JOIN tags t ON t.id=pt.tag_id
            LEFT JOIN project_photos pp ON pp.photo_id=ph.id
            LEFT JOIN projects pr ON pr.id=pp.project_id
            WHERE ph.filename LIKE ? COLLATE NOCASE
               OR ph.path LIKE ? COLLATE NOCASE
               OR t.name LIKE ? COLLATE NOCASE
               OR pr.name LIKE ? COLLATE NOCASE
            ORDER BY ph.id DESC
            LIMIT ?
            """,
            (pattern, pattern, pattern, pattern, limit),
        ).fetchall()
    return [dict(row) for row in rows]
