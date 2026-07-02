"""Server-rendered web app: cookie auth, CSRF, all main pages."""
from httpx import ASGITransport, AsyncClient

from app.main import app
from tests.conftest import unique_phone


async def web_client() -> AsyncClient:
    return AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test", follow_redirects=False
    )


async def csrf_of(client: AsyncClient) -> str:
    if "sq_csrf" not in client.cookies:
        await client.get("/login")
    return client.cookies["sq_csrf"]


async def web_register(client: AsyncClient, name: str = "مستخدم ويب") -> str:
    phone = unique_phone()
    token = await csrf_of(client)
    resp = await client.post(
        "/register",
        data={"csrf_token": token, "name": name, "phone": phone, "password": "password123"},
    )
    assert resp.status_code == 303, resp.text
    assert "sq_access" in client.cookies
    return phone


async def test_home_and_seo_pages(client):
    resp = await client.get("/")
    assert resp.status_code == 200
    assert "سوقنا" in resp.text or "Souqna" in resp.text
    resp = await client.get("/search?q=whatever")
    assert resp.status_code == 200
    resp = await client.get("/static/style.css")
    assert resp.status_code == 200


async def test_web_auth_and_csrf():
    async with await web_client() as c:
        # CSRF required
        resp = await c.get("/login")
        resp = await c.post("/login", data={"csrf_token": "forged", "phone": "07701234567", "password": "x"})
        assert resp.status_code == 403

        phone = await web_register(c)

        # logout clears cookies
        resp = await c.post("/logout", data={"csrf_token": await csrf_of(c)})
        assert resp.status_code == 303

        # login again
        resp = await c.post(
            "/login",
            data={"csrf_token": await csrf_of(c), "phone": phone, "password": "password123", "next": "/my"},
        )
        assert resp.status_code == 303 and resp.headers["location"] == "/my"

        # wrong password shows arabic error
        await c.post("/logout", data={"csrf_token": await csrf_of(c)})
        resp = await c.post(
            "/login", data={"csrf_token": await csrf_of(c), "phone": phone, "password": "bad-pass"}
        )
        assert resp.status_code == 400 and "غير صحيحة" in resp.text


async def test_web_requires_login_redirects():
    async with await web_client() as c:
        for path in ("/post", "/my", "/favorites", "/chat", "/notifications"):
            resp = await c.get(path)
            assert resp.status_code == 303
            assert resp.headers["location"].startswith("/login")


async def test_web_full_marketplace_flow():
    from tests.conftest import jpeg_bytes

    async with await web_client() as seller, await web_client() as buyer:
        await web_register(seller, "بائع ويب")
        await web_register(buyer, "مشتري ويب")

        # seller posts a listing with an image
        resp = await seller.post(
            "/post",
            data={
                "csrf_token": await csrf_of(seller),
                "title": "دراجة هوائية جبلية",
                "description": "دراجة بحالة جيدة جداً",
                "price": "150000",
                "category_id": "12",
                "governorate": "بغداد",
                "city": "المنصور",
                "condition": "used",
            },
            files={"images": ("bike.jpg", jpeg_bytes((30, 90, 200)), "image/jpeg")},
        )
        assert resp.status_code == 303, resp.text
        listing_url = resp.headers["location"]
        lid = int(listing_url.rsplit("/", 1)[1])

        # public detail page renders
        resp = await buyer.get(listing_url)
        assert resp.status_code == 200 and "دراجة هوائية" in resp.text

        # buyer favorites it
        resp = await buyer.post(
            f"/favorites/{lid}/toggle", data={"csrf_token": await csrf_of(buyer)}
        )
        assert resp.status_code == 303
        resp = await buyer.get("/favorites")
        assert "دراجة هوائية" in resp.text

        # buyer messages the seller
        resp = await buyer.post(
            f"/listings/{lid}/message",
            data={"csrf_token": await csrf_of(buyer), "body": "هل ما زالت متوفرة؟"},
        )
        assert resp.status_code == 303
        chat_url = resp.headers["location"]

        # seller sees conversation + notification badge, replies
        resp = await seller.get("/chat")
        assert "مشتري ويب" in resp.text
        resp = await seller.get(chat_url)
        assert "هل ما زالت متوفرة؟" in resp.text
        resp = await seller.post(
            f"{chat_url}/send", data={"csrf_token": await csrf_of(seller), "body": "نعم متوفرة"}
        )
        assert resp.status_code == 303
        resp = await buyer.get(chat_url)
        assert "نعم متوفرة" in resp.text

        # notifications page + read-all
        resp = await seller.get("/notifications")
        assert resp.status_code == 200
        resp = await seller.post(
            "/notifications/read-all", data={"csrf_token": await csrf_of(seller)}
        )
        assert resp.status_code == 303

        # buyer reports the listing
        resp = await buyer.post(
            "/report",
            data={
                "csrf_token": await csrf_of(buyer),
                "listing_id": str(lid),
                "reason": "spam",
                "details": "مكرر",
            },
        )
        assert resp.status_code == 303

        # seller edits then marks sold
        resp = await seller.post(
            f"/listings/{lid}/edit",
            data={
                "csrf_token": await csrf_of(seller),
                "title": "دراجة هوائية جبلية (محدث)",
                "description": "دراجة بحالة جيدة جداً",
                "price": "140000",
                "category_id": "12",
                "governorate": "بغداد",
                "city": "المنصور",
                "condition": "used",
            },
        )
        assert resp.status_code == 303
        resp = await seller.post(
            f"/listings/{lid}/status",
            data={"csrf_token": await csrf_of(seller), "status": "sold"},
        )
        assert resp.status_code == 303
        resp = await seller.get(f"/listings/{lid}")
        assert "تم البيع" in resp.text


async def test_web_admin_dashboard():
    async with await web_client() as c:
        # anonymous → redirect to login
        resp = await c.get("/admin")
        assert resp.status_code == 303

        # normal user → 403
        await web_register(c, "عادي")
        resp = await c.get("/admin")
        assert resp.status_code == 403

    async with await web_client() as admin:
        resp = await admin.get("/login")
        resp = await admin.post(
            "/login",
            data={"csrf_token": await csrf_of(admin), "phone": "07700000001", "password": "admin-secret"},
        )
        assert resp.status_code == 303
        for path in ("/admin", "/admin/users", "/admin/listings", "/admin/reports",
                     "/admin/categories", "/admin/audit"):
            resp = await admin.get(path)
            assert resp.status_code == 200, path
