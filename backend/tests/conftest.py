"""Test setup: SQLite database + ASGI test client (no Docker needed).

Env vars are set BEFORE importing the app so Settings picks them up.
"""
import io
import itertools
import os
import tempfile

_TMP = tempfile.mkdtemp(prefix="souqna-tests-")
os.environ["DATABASE_URL"] = f"sqlite+aiosqlite:///{_TMP}/test.db"
os.environ["UPLOAD_DIR"] = f"{_TMP}/uploads"
os.environ["SECRET_KEY"] = "test-secret-key"
os.environ["APP_ENV"] = "development"
os.environ["STORAGE_BACKEND"] = "local"
os.environ["REPORTS_AUTO_HIDE_THRESHOLD"] = "3"
os.environ["TELEGRAM_BOT_TOKEN"] = ""
os.environ["ADMIN_PHONE"] = "07700000001"
os.environ["ADMIN_PASSWORD"] = "admin-secret"

import pytest
from httpx import ASGITransport, AsyncClient
from PIL import Image

from app.db.base import Base
from app.db.session import engine
from app.main import app
from app.seed import seed_admin, seed_categories

_phone_counter = itertools.count(7710000000)


@pytest.fixture(scope="session", autouse=True)
def _disable_rate_limit():
    app.state.limiter.enabled = False
    yield


@pytest.fixture(scope="session", autouse=True)
async def _db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    await seed_categories()
    await seed_admin()
    yield
    await engine.dispose()


@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


def unique_phone() -> str:
    return f"0{next(_phone_counter)}"


async def register_user(client: AsyncClient, name: str = "مستخدم تجريبي") -> dict:
    """Register a fresh user; returns {user, tokens, phone, password, headers}."""
    phone, password = unique_phone(), "password123"
    resp = await client.post(
        "/api/auth/register", json={"name": name, "phone": phone, "password": password}
    )
    assert resp.status_code == 201, resp.text
    data = resp.json()
    data["phone"], data["password"] = phone, password
    data["headers"] = {"Authorization": f"Bearer {data['tokens']['access_token']}"}
    return data


async def admin_headers(client: AsyncClient) -> dict:
    resp = await client.post(
        "/api/auth/login", json={"phone": "07700000001", "password": "admin-secret"}
    )
    assert resp.status_code == 200, resp.text
    return {"Authorization": f"Bearer {resp.json()['tokens']['access_token']}"}


async def create_listing(client: AsyncClient, headers: dict, **overrides) -> dict:
    payload = {
        "title": "آيفون 13 برو للبيع",
        "description": "بحالة ممتازة مع الكارتون",
        "price": 950000,
        "category_id": 4,
        "governorate": "بغداد",
        "city": "الكرادة",
        "condition": "used",
        "negotiable": True,
    }
    payload.update(overrides)
    resp = await client.post("/api/listings", json=payload, headers=headers)
    assert resp.status_code == 201, resp.text
    return resp.json()


def jpeg_bytes(color=(200, 30, 30), size=(320, 240)) -> bytes:
    buf = io.BytesIO()
    Image.new("RGB", size, color).save(buf, format="JPEG")
    return buf.getvalue()
