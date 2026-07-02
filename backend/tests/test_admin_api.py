from tests.conftest import admin_headers, create_listing, register_user


async def test_stats_and_users(client):
    admin = await admin_headers(client)
    resp = await client.get("/api/admin/stats", headers=admin)
    assert resp.status_code == 200
    stats = resp.json()
    for key in ("users", "listings", "active_listings", "messages", "open_reports", "banned_users"):
        assert key in stats

    resp = await client.get("/api/admin/users", headers=admin)
    assert resp.status_code == 200
    assert resp.json()["total"] >= 1


async def test_ban_and_role_management(client):
    admin = await admin_headers(client)
    user = await register_user(client)
    uid = user["user"]["id"]

    resp = await client.patch(f"/api/admin/users/{uid}", json={"is_banned": True}, headers=admin)
    assert resp.status_code == 200
    resp = await client.post(
        "/api/auth/login", json={"phone": user["phone"], "password": user["password"]}
    )
    assert resp.status_code == 403
    resp = await client.patch(f"/api/admin/users/{uid}", json={"is_banned": False}, headers=admin)
    assert resp.status_code == 200

    resp = await client.patch(f"/api/admin/users/{uid}", json={"role": "supergod"}, headers=admin)
    assert resp.status_code == 400


async def test_admin_listing_moderation(client):
    admin = await admin_headers(client)
    owner = await register_user(client)
    listing = await create_listing(client, owner["headers"])
    lid = listing["id"]

    resp = await client.patch(
        f"/api/admin/listings/{lid}/status", json={"status": "hidden"}, headers=admin
    )
    assert resp.status_code == 200
    assert resp.json()["status"] == "hidden"
    # owner notified
    resp = await client.get("/api/notifications", headers=owner["headers"])
    assert any(n["type"] == "moderation" for n in resp.json()["items"])

    resp = await client.delete(f"/api/admin/listings/{lid}", headers=admin)
    assert resp.status_code == 204


async def test_admin_categories(client):
    admin = await admin_headers(client)
    resp = await client.post(
        "/api/admin/categories",
        json={"slug": "test-cat", "name_ar": "قسم تجريبي", "sort_order": 99},
        headers=admin,
    )
    assert resp.status_code == 201
    cid = resp.json()["id"]

    resp = await client.post(
        "/api/admin/categories", json={"slug": "test-cat", "name_ar": "مكرر"}, headers=admin
    )
    assert resp.status_code == 409

    resp = await client.patch(
        f"/api/admin/categories/{cid}", json={"is_active": False}, headers=admin
    )
    assert resp.status_code == 200

    # inactive category not in the public list
    resp = await client.get("/api/categories")
    assert all(c["slug"] != "test-cat" for c in resp.json())


async def test_admin_requires_admin_role(client):
    user = await register_user(client)
    for path in ("/api/admin/stats", "/api/admin/users", "/api/admin/audit"):
        resp = await client.get(path, headers=user["headers"])
        assert resp.status_code == 403
