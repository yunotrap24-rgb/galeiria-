from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from .db import connect
from .scanner import scan_library

_executor = ThreadPoolExecutor(max_workers=1, thread_name_prefix="galeiria-indexer")


def create_scan_job(root_value: str) -> int:
    root = Path(root_value).expanduser().resolve()
    if not root.exists() or not root.is_dir():
        raise ValueError("A pasta da biblioteca não existe ou não é um diretório.")

    with connect() as conn:
        cursor = conn.execute(
            "INSERT INTO scan_jobs(library_root, status) VALUES (?, 'queued')",
            (str(root),),
        )
        job_id = int(cursor.lastrowid)
        conn.commit()

    _executor.submit(_run_scan_job, job_id, str(root))
    return job_id


def _run_scan_job(job_id: int, root: str) -> None:
    with connect() as conn:
        conn.execute(
            "UPDATE scan_jobs SET status='running', started_at=CURRENT_TIMESTAMP WHERE id=?",
            (job_id,),
        )
        conn.commit()

    def progress(stats: dict[str, int]) -> None:
        with connect() as conn:
            conn.execute(
                """
                UPDATE scan_jobs
                SET found=?, indexed=?, skipped=?, errors=?
                WHERE id=?
                """,
                (stats["found"], stats["indexed"], stats["skipped"], stats["errors"], job_id),
            )
            conn.commit()

    try:
        stats = scan_library(root, progress=progress)
        with connect() as conn:
            conn.execute(
                """
                UPDATE scan_jobs
                SET status='completed', found=?, indexed=?, skipped=?, errors=?,
                    finished_at=CURRENT_TIMESTAMP
                WHERE id=?
                """,
                (stats["found"], stats["indexed"], stats["skipped"], stats["errors"], job_id),
            )
            conn.commit()
    except Exception as exc:
        with connect() as conn:
            conn.execute(
                """
                UPDATE scan_jobs
                SET status='failed', error_message=?, finished_at=CURRENT_TIMESTAMP
                WHERE id=?
                """,
                (str(exc), job_id),
            )
            conn.commit()


def get_scan_job(job_id: int) -> dict | None:
    with connect() as conn:
        row = conn.execute("SELECT * FROM scan_jobs WHERE id=?", (job_id,)).fetchone()
    return dict(row) if row else None
