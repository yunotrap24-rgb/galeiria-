from __future__ import annotations

import hmac
import ipaddress
import os
import secrets
from pathlib import Path

from fastapi import Request

from .db import data_dir

TOKEN_FILENAME = "server-token"


def token_path() -> Path:
    return data_dir() / TOKEN_FILENAME


def server_token() -> str:
    path = token_path()
    if path.exists():
        value = path.read_text(encoding="utf-8").strip()
        if value:
            return value

    value = secrets.token_urlsafe(32)
    path.write_text(value, encoding="utf-8")
    try:
        os.chmod(path, 0o600)
    except OSError:
        pass
    return value


def is_loopback_host(host: str | None) -> bool:
    if not host:
        return False
    if host.lower() in {"localhost", "testclient"}:
        return True
    try:
        return ipaddress.ip_address(host).is_loopback
    except ValueError:
        return False


def request_is_loopback(request: Request) -> bool:
    return is_loopback_host(request.client.host if request.client else None)


def bearer_token(request: Request) -> str | None:
    value = request.headers.get("authorization", "")
    prefix = "bearer "
    if not value.lower().startswith(prefix):
        return None
    return value[len(prefix):].strip()


def request_has_valid_token(request: Request) -> bool:
    candidate = bearer_token(request)
    return bool(candidate and hmac.compare_digest(candidate, server_token()))
