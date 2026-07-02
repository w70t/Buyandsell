"""Favorites, messages/chat, notifications."""
from tests.conftest import create_listing, register_user


async def test_favorites_flow_with_owner_notification(client):
    seller = await register_user(client, "بائع")
    buyer = await register_user(client, "مشترٍ")
    listing = await create_listing(client, seller["headers"])
    lid = listing["id"]

    resp = await client.post(f"/api/favorites/{lid}", headers=buyer["headers"])
    assert resp.status_code == 201
    resp = await client.get("/api/favorites/ids", headers=buyer["headers"])
    assert lid in resp.json()
    resp = await client.get("/api/favorites", headers=buyer["headers"])
    assert any(l["id"] == lid for l in resp.json())

    # seller got a favorite notification
    resp = await client.get("/api/notifications", headers=seller["headers"])
    assert any(n["type"] == "favorite" for n in resp.json()["items"])

    resp = await client.delete(f"/api/favorites/{lid}", headers=buyer["headers"])
    assert resp.status_code == 204
    resp = await client.get("/api/favorites/ids", headers=buyer["headers"])
    assert lid not in resp.json()


async def test_chat_flow_with_notifications(client):
    seller = await register_user(client, "بائع")
    buyer = await register_user(client, "مشترٍ")
    listing = await create_listing(client, seller["headers"])

    # buyer cannot message themselves
    resp = await client.post(
        "/api/messages",
        json={"listing_id": listing["id"], "receiver_id": buyer["user"]["id"], "body": "hi"},
        headers=buyer["headers"],
    )
    assert resp.status_code == 400

    resp = await client.post(
        "/api/messages",
        json={"listing_id": listing["id"], "receiver_id": seller["user"]["id"], "body": "هل السعر قابل للتفاوض؟"},
        headers=buyer["headers"],
    )
    assert resp.status_code == 201
    cid = resp.json()["conversation_id"]

    # seller sees the conversation with 1 unread + a notification
    resp = await client.get("/api/messages/conversations", headers=seller["headers"])
    convs = resp.json()
    assert any(c["conversation_id"] == cid and c["unread"] == 1 for c in convs)
    resp = await client.get("/api/notifications/unread-count", headers=seller["headers"])
    assert resp.json()["unread"] >= 1

    # reading marks as read; seller replies
    resp = await client.get(f"/api/messages/conversation/{cid}", headers=seller["headers"])
    assert resp.status_code == 200
    resp = await client.post(
        "/api/messages",
        json={"listing_id": listing["id"], "receiver_id": buyer["user"]["id"], "body": "نعم قابل"},
        headers=seller["headers"],
    )
    assert resp.status_code == 201
    resp = await client.get(f"/api/messages/conversation/{cid}", headers=buyer["headers"])
    assert len(resp.json()) == 2

    # stranger cannot read the thread
    stranger = await register_user(client)
    resp = await client.get(f"/api/messages/conversation/{cid}", headers=stranger["headers"])
    assert resp.status_code == 403


async def test_notifications_read_endpoints(client):
    seller = await register_user(client, "بائع")
    buyer = await register_user(client, "مشترٍ")
    listing = await create_listing(client, seller["headers"])
    await client.post(f"/api/favorites/{listing['id']}", headers=buyer["headers"])

    resp = await client.get("/api/notifications", headers=seller["headers"])
    items = resp.json()["items"]
    assert items and not items[0]["is_read"]
    nid = items[0]["id"]

    resp = await client.post(f"/api/notifications/{nid}/read", headers=seller["headers"])
    assert resp.status_code == 204
    resp = await client.post("/api/notifications/read-all", headers=seller["headers"])
    assert resp.status_code == 204
    resp = await client.get("/api/notifications/unread-count", headers=seller["headers"])
    assert resp.json()["unread"] == 0

    # cannot read someone else's notification
    resp = await client.post(f"/api/notifications/{nid}/read", headers=buyer["headers"])
    assert resp.status_code == 404
