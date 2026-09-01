from __future__ import annotations

import os
import sqlite3
from pathlib import Path


def data_dir() -> Path:
    root = Path(os.environ.get("GALEIRIA_DATA_DIR", Path.home() / ".galeiria"))
    root.mkdir(parents=True, exist_ok=True)
    return root


def db_path() -> Path:
    return data_dir() / "galeiria.sqlite3"


def connect() -> sqlite3.Connection:
    conn = sqlite3.connect(db_path())
    conn.row_factory = sqlite3.Row
    return conn


def init_db() -> None:
    with connect() as conn:
        conn.executescript(
            """
            PRAGMA journal_mode=WAL;

            CREATE TABLE IF NOT EXISTS photos (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                library_root TEXT NOT NULL,
                path TEXT NOT NULL UNIQUE,
                filename TEXT NOT NULL,
                sha256 TEXT NOT NULL,
                size_bytes INTEGER NOT NULL,
                modified_ns INTEGER NOT NULL,
                width INTEGER,
                height INTEGER,
                image_format TEXT,
                thumbnail_path TEXT,
                indexed_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            CREATE INDEX IF NOT EXISTS idx_photos_sha256 ON photos(sha256);
            CREATE INDEX IF NOT EXISTS idx_photos_filename ON photos(filename);
            """
        )
