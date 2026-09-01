from __future__ import annotations

from .db import connect


def hamming_distance_hex(left: str, right: str) -> int:
    return (int(left, 16) ^ int(right, 16)).bit_count()


def exact_duplicate_groups(limit: int = 100) -> list[dict]:
    limit = max(1, min(limit, 500))
    with connect() as conn:
        hashes = conn.execute(
            """
            SELECT sha256, COUNT(*) AS count, SUM(size_bytes) AS total_bytes
            FROM photos
            GROUP BY sha256
            HAVING COUNT(*) > 1
            ORDER BY count DESC, total_bytes DESC
            LIMIT ?
            """,
            (limit,),
        ).fetchall()
        groups = []
        for item in hashes:
            photos = conn.execute(
                """
                SELECT id, filename, path, size_bytes, width, height, image_format
                FROM photos WHERE sha256=? ORDER BY size_bytes DESC, id ASC
                """,
                (item["sha256"],),
            ).fetchall()
            groups.append({
                "sha256": item["sha256"],
                "count": item["count"],
                "total_bytes": item["total_bytes"],
                "photos": [dict(row) for row in photos],
            })
        return groups


def near_duplicate_pairs(max_distance: int = 5, limit: int = 200) -> list[dict]:
    """Return conservative near-duplicate candidates using dHash distance.

    The bootstrap caps the comparison set to protect the API on large libraries.
    A BK-tree/LSH or other indexed approach can replace this later.
    """
    max_distance = max(0, min(max_distance, 16))
    limit = max(1, min(limit, 1000))
    with connect() as conn:
        rows = conn.execute(
            """
            SELECT id, filename, path, sha256, perceptual_hash, width, height, size_bytes
            FROM photos
            WHERE perceptual_hash IS NOT NULL
            ORDER BY id DESC
            LIMIT 5000
            """
        ).fetchall()

    pairs: list[dict] = []
    for index, left in enumerate(rows):
        for right in rows[index + 1:]:
            if left["sha256"] == right["sha256"]:
                continue
            distance = hamming_distance_hex(left["perceptual_hash"], right["perceptual_hash"])
            if distance <= max_distance:
                pairs.append({
                    "distance": distance,
                    "similarity": round(1 - distance / 64, 4),
                    "left": dict(left),
                    "right": dict(right),
                })
                if len(pairs) >= limit:
                    return sorted(pairs, key=lambda item: item["distance"])
    return sorted(pairs, key=lambda item: item["distance"])
