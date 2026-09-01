from __future__ import annotations

import os

import uvicorn


def main() -> None:
    host = os.environ.get("GALEIRIA_HOST", "0.0.0.0")
    port = int(os.environ.get("GALEIRIA_PORT", "8765"))
    uvicorn.run("app.main:app", host=host, port=port, reload=False)


if __name__ == "__main__":
    main()
