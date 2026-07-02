from tests.conftest import create_listing, jpeg_bytes, register_user


async def test_listing_crud_and_images(client):
    user = await register_user(client)
    listing = await create_listing(client, user["headers"])
    lid = listing["id"]
    assert listing["title"] == "آيفون 13 برو للبيع"

    # image upload
    resp = await client.post(
        f"/api/listings/{lid}/images",
        files={"file": ("photo.jpg", jpeg_bytes(), "image/jpeg")},
        headers=user["headers"],
    )
    assert resp.status_code == 201, resp.text
    assert len(resp.json()["images"]) == 1

    # bogus image rejected
    resp = await client.post(
        f"/api/listings/{lid}/images",
        files={"file": ("evil.jpg", b"not-an-image", "image/jpeg")},
        headers=user["headers"],
    )
    assert resp.status_code == 400

    # detail view increments views for non-owner
    other = await register_user(client)
    resp = await client.get(f"/api/listings/{lid}", headers=other["headers"])
    assert resp.status_code == 200
    assert resp.json()["views"] == 1

    # update
    resp = await client.patch(
        f"/api/listings/{lid}", json={"price": 900000, "status": "sold"}, headers=user["headers"]
    )
    assert resp.status_code == 200
    assert resp.json()["price"] == 900000

    # non-owner cannot edit
    resp = await client.patch(f"/api/listings/{lid}", json={"price": 1}, headers=other["headers"])
    assert resp.status_code == 403

    # delete
    resp = await client.delete(f"/api/listings/{lid}", headers=user["headers"])
    assert resp.status_code == 204
    resp = await client.get(f"/api/listings/{lid}")
    assert resp.status_code == 404


async def test_search_and_filters(client):
    user = await register_user(client)
    await create_listing(client, user["headers"], title="سيارة تويوتا كورولا 2018", category_id=3, governorate="البصرة", price=15000000)
    await create_listing(client, user["headers"], title="غسالة سامسونج", category_id=5, governorate="بغداد", price=250000)

    resp = await client.get("/api/listings", params={"q": "تويوتا"})
    assert resp.status_code == 200
    items = resp.json()["items"]
    assert any("تويوتا" in i["title"] for i in items)
    assert all("غسالة" not in i["title"] for i in items)

    resp = await client.get("/api/listings", params={"governorate": "البصرة"})
    assert all(i["governorate"] == "البصرة" for i in resp.json()["items"])

    resp = await client.get("/api/listings", params={"min_price": 1000000})
    assert all(i["price"] >= 1000000 for i in resp.json()["items"])

    resp = await client.get("/api/listings", params={"sort": "price_asc"})
    prices = [i["price"] for i in resp.json()["items"]]
    assert prices == sorted(prices)


async def test_hidden_listing_invisible_to_others(client):
    owner = await register_user(client)
    listing = await create_listing(client, owner["headers"])
    await client.patch(
        f"/api/listings/{listing['id']}", json={"status": "hidden"}, headers=owner["headers"]
    )
    resp = await client.get(f"/api/listings/{listing['id']}")
    assert resp.status_code == 404
    resp = await client.get(f"/api/listings/{listing['id']}", headers=owner["headers"])
    assert resp.status_code == 200


async def test_mine_endpoint(client):
    user = await register_user(client)
    await create_listing(client, user["headers"], title="إعلاني الخاص")
    resp = await client.get("/api/listings/mine", headers=user["headers"])
    assert resp.status_code == 200
    assert any(l["title"] == "إعلاني الخاص" for l in resp.json())
