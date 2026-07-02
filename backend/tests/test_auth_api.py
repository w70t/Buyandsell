from tests.conftest import register_user, unique_phone


async def test_register_login_me_refresh(client):
    data = await register_user(client, "أحمد")
    assert data["user"]["name"] == "أحمد"

    # duplicate phone
    resp = await client.post(
        "/api/auth/register",
        json={"name": "آخر", "phone": data["phone"], "password": "password123"},
    )
    assert resp.status_code == 409

    # wrong password
    resp = await client.post(
        "/api/auth/login", json={"phone": data["phone"], "password": "wrong-pass"}
    )
    assert resp.status_code == 401

    # correct login
    resp = await client.post(
        "/api/auth/login", json={"phone": data["phone"], "password": data["password"]}
    )
    assert resp.status_code == 200

    # me
    resp = await client.get("/api/auth/me", headers=data["headers"])
    assert resp.status_code == 200
    assert resp.json()["phone"] == data["phone"]

    # refresh
    resp = await client.post(
        "/api/auth/refresh", json={"refresh_token": data["tokens"]["refresh_token"]}
    )
    assert resp.status_code == 200
    assert "access_token" in resp.json()


async def test_invalid_phone_rejected(client):
    resp = await client.post(
        "/api/auth/register", json={"name": "بدر", "phone": "12345", "password": "password123"}
    )
    assert resp.status_code == 422


async def test_me_requires_auth(client):
    resp = await client.get("/api/auth/me")
    assert resp.status_code == 401
