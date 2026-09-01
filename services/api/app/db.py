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
    conn = sqlite3.connect(db_path(), timeout=30, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys=ON")
    return conn


def _ensure_column(conn: sqlite3.Connection, table: str, column: str, ddl: str) -> None:
    columns = {row["name"] for row in conn.execute(f"PRAGMA table_info({table})")}
    if column not in columns:
        conn.execute(f"ALTER TABLE {table} ADD COLUMN {ddl}")


def init_db() -> None:
    with connect() as conn:
        conn.executescript(
            """
            PRAGMA journal_mode=WAL;

            CREATE TABLE IF NOT EXISTS libraries (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                root TEXT NOT NULL UNIQUE,
                enabled INTEGER NOT NULL DEFAULT 1,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                last_scanned_at TEXT
            );

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

            CREATE TABLE IF NOT EXISTS scan_jobs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                library_root TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'queued',
                found INTEGER NOT NULL DEFAULT 0,
                indexed INTEGER NOT NULL DEFAULT 0,
                skipped INTEGER NOT NULL DEFAULT 0,
                errors INTEGER NOT NULL DEFAULT 0,
                error_message TEXT,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                started_at TEXT,
                finished_at TEXT
            );

            CREATE TABLE IF NOT EXISTS tags (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL UNIQUE COLLATE NOCASE,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS photo_tags (
                photo_id INTEGER NOT NULL REFERENCES photos(id) ON DELETE CASCADE,
                tag_id INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
                source TEXT NOT NULL DEFAULT 'user',
                confidence REAL,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY(photo_id, tag_id)
            );

            CREATE TABLE IF NOT EXISTS projects (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL UNIQUE COLLATE NOCASE,
                description TEXT NOT NULL DEFAULT '',
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS project_photos (
                project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
                photo_id INTEGER NOT NULL REFERENCES photos(id) ON DELETE CASCADE,
                stage TEXT NOT NULL DEFAULT 'reference',
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY(project_id, photo_id)
            );

            CREATE INDEX IF NOT EXISTS idx_photos_sha256 ON photos(sha256);
            CREATE INDEX IF NOT EXISTS idx_photos_filename ON photos(filename);
            CREATE INDEX IF NOT EXISTS idx_scan_jobs_status ON scan_jobs(status);
            """
        )
        _ensure_column(conn, "photos", "perceptual_hash", "perceptual_hash TEXT")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_photos_perceptual_hash ON photos(perceptual_hash)")
        conn.commit()
