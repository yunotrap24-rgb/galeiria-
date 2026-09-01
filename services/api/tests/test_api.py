from __future__ import annotations

from fastapi.testclient import TestClient

from app.db import init_db
from app.main import app


def test_health_and_empty_stats(tmp_path, monkeypatch):
    monkeypatch.setenv("GALEIRIA_DATA_DIR", str(tmp_path / "data"))
    init_db()
    with TestClient(app) as client:
        health = client.get("/health")
        stats = client.get("/api/v1/stats")

    assert health.status_code == 200
    assert health.json()["status"] == "ok"
    assert stats.json() == {"photos": 0, "libraries": 0, "exact_duplicate_groups": 0}
