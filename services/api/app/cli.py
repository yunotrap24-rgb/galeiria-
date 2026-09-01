from __future__ import annotations

import os

import uvicorn


def main() -> None:
    # Safe default: expose only on this PC. LAN mode must be enabled explicitly.
    host = os.environ.get("GALEIRIA_HOST", "127.0.0.1")
    port = int(os.environ.get("GALEIRIA_PORT", "8765"))
    uvicorn.run("app.main:app", host=host, port=port, reload=False)


if __name__ == "__main__":
    main()
