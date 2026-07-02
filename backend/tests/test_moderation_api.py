"""Reports, auto-hide, admin moderation queue, audit log."""
from tests.conftest import admin_headers, create_listing, register_user


async def test_report_validation(client):
    owner = await register_user(client)
    listing = await create_listing(client, owner["headers"])

    # cannot report own listing
    resp = await client.post(
        "/api/reports", json={"listing_id": listing["id"], "reason": "spam"}, headers=owner["headers"]
    )
    assert resp.status_code == 400

    # must have a target
    resp = await client.post("/api/reports", json={"reason": "spam"}, headers=owner["headers"])
    assert resp.status_code == 422

    # happy path + duplicate blocked
    reporter = await register_user(client)
    resp = await client.post(
        "/api/reports",
        json={"listing_id": listing["id"], "reason": "scam", "details": "سعر وهمي"},
        headers=reporter["headers"],
    )
    assert resp.status_code == 201
    assert resp.json()["status"] == "open"
    resp = await client.post(
        "/api/reports", json={"listing_id": listing["id"], "reason": "scam"}, headers=reporter["headers"]
    )
    assert resp.status_code == 409


async def test_auto_hide_after_threshold(client):
    owner = await register_user(client)
    listing = await create_listing(client, owner["headers"], title="إعلان مشبوه")
    lid = listing["id"]

    # threshold is 3 in tests (conftest env)
    for _ in range(3):
        reporter = await register_user(client)
        resp = await client.post(
            "/api/reports", json={"listing_id": lid, "reason": "scam"}, headers=reporter["headers"]
        )
        assert resp.status_code == 201

    # hidden from the public now
    resp = await client.get(f"/api/listings/{lid}")
    assert resp.status_code == 404
    # owner got a moderation notification
    resp = await client.get("/api/notifications", headers=owner["headers"])
    assert any(n["type"] == "moderation" for n in resp.json()["items"])


async def test_admin_resolve_and_dismiss(client):
    admin = await admin_headers(client)
    owner = await register_user(client, "مخالف")
    reporter = await register_user(client)
    listing = await create_listing(client, owner["headers"])

    resp = await client.post(
        "/api/reports", json={"listing_id": listing["id"], "reason": "prohibited"}, headers=reporter["headers"]
    )
    report_id = resp.json()["id"]

    # queue shows it
    resp = await client.get("/api/admin/reports", params={"status": "open"}, headers=admin)
    assert any(r["id"] == report_id for r in resp.json()["items"])

    # resolve with ban_user (reported_user auto-set to listing seller)
    resp = await client.post(
        f"/api/admin/reports/{report_id}/resolve",
        json={"action": "ban_user", "note": "احتيال متكرر"},
        headers=admin,
    )
    assert resp.status_code == 200
    assert resp.json()["status"] == "resolved"

    # banned user can no longer log in
    resp = await client.post(
        "/api/auth/login", json={"phone": owner["phone"], "password": owner["password"]}
    )
    assert resp.status_code == 403

    # double-resolve blocked
    resp = await client.post(
        f"/api/admin/reports/{report_id}/resolve", json={"action": "none"}, headers=admin
    )
    assert resp.status_code == 409

    # dismiss another report
    reporter2 = await register_user(client)
    other_owner = await register_user(client)
    listing2 = await create_listing(client, other_owner["headers"])
    resp = await client.post(
        "/api/reports", json={"listing_id": listing2["id"], "reason": "other"}, headers=reporter2["headers"]
    )
    rid2 = resp.json()["id"]
    resp = await client.post(f"/api/admin/reports/{rid2}/dismiss", headers=admin)
    assert resp.json()["status"] == "dismissed"

    # audit log recorded the actions
    resp = await client.get("/api/admin/audit", headers=admin)
    actions = [e["action"] for e in resp.json()["items"]]
    assert "resolve_report:ban_user" in actions
    assert "dismiss_report" in actions


async def test_reports_require_admin(client):
    user = await register_user(client)
    resp = await client.get("/api/admin/reports", headers=user["headers"])
    assert resp.status_code == 403
