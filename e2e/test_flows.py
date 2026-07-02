"""End-to-end browser verification of every Souqna user flow.

Runs a real Chromium against the full Docker stack (nginx + api + postgres):

    docker compose up -d --build
    pip install playwright pytest && python -m pytest e2e/ -v

Override the target with E2E_BASE_URL (default http://localhost:8080) and the
seeded admin credentials with E2E_ADMIN_PHONE / E2E_ADMIN_PASSWORD.
"""
import os
import time

import pytest
from playwright.sync_api import Page, expect, sync_playwright

BASE = os.environ.get("E2E_BASE_URL", "http://localhost:8080")
ADMIN_PHONE = os.environ.get("E2E_ADMIN_PHONE", "07700000000")
ADMIN_PASSWORD = os.environ.get("E2E_ADMIN_PASSWORD", "change-me-admin-password")
_STAMP = str(int(time.time()))[-6:]

SELLER = {"name": "بائع الفحص", "phone": f"0771{_STAMP}1", "password": "e2e-pass-123"}
BUYER = {"name": "مشتري الفحص", "phone": f"0772{_STAMP}2", "password": "e2e-pass-123"}
LISTING_TITLE = f"لابتوب ديل للفحص الآلي {_STAMP}"


@pytest.fixture(scope="session")
def browser():
    with sync_playwright() as p:
        # E2E_CHROMIUM overrides the executable when the environment pins its
        # own Chromium build (e.g. sandboxed CI images).
        exe = os.environ.get("E2E_CHROMIUM")
        browser = p.chromium.launch(executable_path=exe) if exe else p.chromium.launch()
        yield browser
        browser.close()


@pytest.fixture(scope="session")
def ctx(browser):
    """One shared context per role keeps sessions (cookies) alive across tests."""
    contexts = {
        "seller": browser.new_context(locale="ar"),
        "buyer": browser.new_context(locale="ar"),
        "admin": browser.new_context(locale="ar"),
        "anon": browser.new_context(locale="ar"),
    }
    yield contexts
    for c in contexts.values():
        c.close()


def page_of(ctx, role) -> Page:
    c = ctx[role]
    return c.pages[0] if c.pages else c.new_page()


def register(page: Page, user: dict):
    page.goto(f"{BASE}/register")
    page.fill("input[name=name]", user["name"])
    page.fill("input[name=phone]", user["phone"])
    page.fill("input[name=password]", user["password"])
    page.click("[data-test=register-submit]")
    page.wait_for_url(f"{BASE}/")


def login(page: Page, phone: str, password: str):
    page.goto(f"{BASE}/login")
    page.fill("input[name=phone]", phone)
    page.fill("input[name=password]", password)
    page.click("[data-test=login-submit]")


# ---- Flow 1: anonymous browsing ----
def test_home_renders_categories_and_search(ctx):
    page = page_of(ctx, "anon")
    page.goto(BASE)
    expect(page.locator("[data-test=category-tile]").first).to_be_visible()
    expect(page.locator("[data-test=nav-login]")).to_be_visible()
    page.fill(".nav-search input[name=q]", "أي شيء")
    page.click(".nav-search button")
    page.wait_for_url("**/search?**")
    expect(page.locator("[data-test=results-count]")).to_be_visible()


# ---- Flow 2: registration ----
def test_register_seller_and_buyer(ctx):
    register(page_of(ctx, "seller"), SELLER)
    expect(page_of(ctx, "seller").locator("[data-test=nav-post]")).to_be_visible()
    register(page_of(ctx, "buyer"), BUYER)
    expect(page_of(ctx, "buyer").locator("[data-test=nav-post]")).to_be_visible()


# ---- Flow 3: login (wrong + right) ----
def test_login_flow(ctx, browser):
    c = browser.new_context()
    page = c.new_page()
    login(page, SELLER["phone"], "wrong-password")
    expect(page.locator("[data-test=auth-error]")).to_be_visible()
    login(page, SELLER["phone"], SELLER["password"])
    page.wait_for_url(f"{BASE}/")
    expect(page.locator("[data-test=nav-post]")).to_be_visible()
    c.close()


# ---- Flow 4: post a listing with an image ----
def test_post_listing_with_image(ctx, tmp_path):
    from PIL import Image

    img = tmp_path / "laptop.jpg"
    Image.new("RGB", (640, 480), (40, 90, 160)).save(img, "JPEG")

    page = page_of(ctx, "seller")
    page.goto(f"{BASE}/post")
    page.fill("input[name=title]", LISTING_TITLE)
    page.fill("textarea[name=description]", "لابتوب ديل XPS بحالة ممتازة، رام 16 وذاكرة 512")
    page.fill("input[name=price]", "1250000")
    page.select_option("select[name=category_id]", label="هواتف وأجهزة")
    page.select_option("select[name=governorate]", "بغداد")
    page.fill("input[name=city]", "زيونة")
    page.set_input_files("input[name=images]", str(img))
    page.click("[data-test=listing-submit]")
    page.wait_for_url("**/listings/*")
    expect(page.locator("[data-test=listing-title]")).to_contain_text("لابتوب ديل")
    expect(page.locator("#main-img")).to_be_visible()


# ---- Flow 5: search finds it, filters work ----
def test_search_and_filters(ctx):
    page = page_of(ctx, "anon")
    page.goto(f"{BASE}/search?q=لابتوب ديل")
    expect(page.locator("[data-test=listing-card]").first).to_be_visible()
    # price filter excludes it
    page.goto(f"{BASE}/search?q=لابتوب ديل&max_price=1000")
    expect(page.locator("[data-test=no-results]")).to_be_visible()
    # governorate filter keeps it
    page.goto(f"{BASE}/search?q=لابتوب ديل&governorate=بغداد&min_price=1000000")
    expect(page.locator("[data-test=listing-card]").first).to_be_visible()


# ---- Flow 6: favorites ----
def test_buyer_favorites_listing(ctx):
    page = page_of(ctx, "buyer")
    page.goto(f"{BASE}/search?q={LISTING_TITLE}")
    page.click("[data-test=listing-card] a.card-link")
    page.wait_for_url("**/listings/*")
    page.click("[data-test=fav-toggle-detail]")
    page.goto(f"{BASE}/favorites")
    expect(page.locator("[data-test=listing-card]").first).to_contain_text("لابتوب ديل")


# ---- Flow 7: chat both directions ----
def test_chat_between_buyer_and_seller(ctx):
    buyer = page_of(ctx, "buyer")
    buyer.goto(f"{BASE}/search?q={LISTING_TITLE}")
    buyer.click("[data-test=listing-card] a.card-link")
    buyer.fill("[data-test=message-form] textarea", "مرحباً، هل السعر نهائي؟")
    buyer.click("[data-test=send-message]")
    buyer.wait_for_url("**/chat/**")
    expect(buyer.locator("[data-test=chat-message]").last).to_contain_text("هل السعر نهائي؟")

    seller = page_of(ctx, "seller")
    seller.goto(f"{BASE}/chat")
    seller.click("[data-test=conversation-item]")
    seller.wait_for_url("**/chat/**")
    expect(seller.locator("[data-test=chat-message]").last).to_contain_text("هل السعر نهائي؟")
    seller.fill("[data-test=chat-form] input[name=body]", "قابل للتفاوض البسيط")
    seller.click("[data-test=chat-send]")
    expect(seller.locator("[data-test=chat-message]").last).to_contain_text("قابل للتفاوض")

    buyer.reload()
    expect(buyer.locator("[data-test=chat-message]").last).to_contain_text("قابل للتفاوض")


# ---- Flow 8: notifications ----
def test_seller_got_notifications(ctx):
    page = page_of(ctx, "seller")
    page.goto(f"{BASE}/notifications")
    items = page.locator("[data-test=notification-item]")
    expect(items.first).to_be_visible()  # favorite + message notifications
    page.click("[data-test=read-all]")
    expect(page.locator(".notif-list li.unread")).to_have_count(0)


# ---- Flow 9: reporting ----
def test_buyer_reports_listing(ctx):
    page = page_of(ctx, "buyer")
    page.goto(f"{BASE}/search?q={LISTING_TITLE}")
    page.click("[data-test=listing-card] a.card-link")
    page.click("[data-test=report-open]")
    page.select_option("[data-test=report-form] select[name=reason]", "spam")
    page.fill("[data-test=report-form] textarea[name=details]", "فحص آلي للبلاغات")
    page.click("[data-test=report-submit]")
    expect(page.locator("[data-test=report-ok]")).to_be_visible()


# ---- Flow 10: seller manages own listing ----
def test_seller_edits_and_marks_sold(ctx):
    page = page_of(ctx, "seller")
    page.goto(f"{BASE}/my")
    page.click("[data-test=listing-card] a.card-link")
    page.wait_for_url("**/listings/*")
    url = page.url
    page.click("[data-test=edit-listing]")
    page.fill("input[name=price]", "1200000")
    page.click("[data-test=listing-submit]")
    page.wait_for_url("**/listings/*")
    expect(page.locator("[data-test=listing-price]")).to_contain_text("1٬200٬000")
    page.select_option("[data-test=owner-controls] select[name=status]", "sold")
    page.click("[data-test=status-save]")
    page.goto(url)
    expect(page.locator(".flash.ok")).to_contain_text("تم البيع")
    # back to active for the admin tests
    page.select_option("[data-test=owner-controls] select[name=status]", "active")
    page.click("[data-test=status-save]")


# ---- Flow 11: admin dashboard + moderation ----
def test_admin_dashboard_and_report_queue(ctx):
    page = page_of(ctx, "admin")
    login(page, ADMIN_PHONE, ADMIN_PASSWORD)
    page.wait_for_url(f"{BASE}/")
    page.goto(f"{BASE}/admin")
    expect(page.locator("[data-test=admin-stats]")).to_be_visible()
    assert int(page.locator("[data-test=stat-users]").inner_text()) >= 3
    assert int(page.locator("[data-test=stat-reports]").inner_text()) >= 1

    # resolve the buyer's report by hiding the listing
    page.goto(f"{BASE}/admin/reports?status=open")
    row = page.locator("[data-test=report-row]").first
    row.locator("select[name=action]").select_option("hide_listing")
    row.locator("input[name=note]").fill("فحص آلي — إخفاء")
    row.locator("[data-test=resolve-submit]").click()
    page.wait_for_url("**/admin/reports**")

    # audit log recorded it
    page.goto(f"{BASE}/admin/audit")
    expect(page.locator("[data-test=audit-row]").first).to_be_visible()


def test_admin_hidden_listing_invisible_and_unhide(ctx):
    anon = page_of(ctx, "anon")
    anon.goto(f"{BASE}/search?q={LISTING_TITLE}")
    expect(anon.locator("[data-test=no-results]")).to_be_visible()

    page = page_of(ctx, "admin")
    page.goto(f"{BASE}/admin/listings?status=hidden")
    page.locator("[data-test=admin-hide-toggle]").first.click()
    anon.goto(f"{BASE}/search?q={LISTING_TITLE}")
    expect(anon.locator("[data-test=listing-card]").first).to_be_visible()


def test_admin_user_management_ban_unban(ctx):
    page = page_of(ctx, "admin")
    page.goto(f"{BASE}/admin/users?q={BUYER['phone']}")
    row = page.locator("[data-test=user-row]").first
    row.locator("[data-test=ban-toggle]").click()
    page.wait_for_url("**/admin/users**")

    # banned buyer cannot log in
    c = page.context.browser.new_context()
    p2 = c.new_page()
    login(p2, BUYER["phone"], BUYER["password"])
    expect(p2.locator("[data-test=auth-error]")).to_be_visible()
    c.close()

    # unban restores access
    page.goto(f"{BASE}/admin/users?q={BUYER['phone']}")
    page.locator("[data-test=user-row]").first.locator("[data-test=ban-toggle]").click()


def test_admin_categories_page(ctx):
    page = page_of(ctx, "admin")
    page.goto(f"{BASE}/admin/categories")
    expect(page.locator("[data-test=categories-table]")).to_be_visible()


# ---- Flow 12: logout ----
def test_logout(ctx):
    page = page_of(ctx, "seller")
    page.goto(BASE)
    page.click("[data-test=nav-logout]")
    page.wait_for_url(f"{BASE}/")
    expect(page.locator("[data-test=nav-login]")).to_be_visible()


# ---- Flow 13: API docs reachable through nginx ----
def test_api_health_and_docs(ctx):
    page = page_of(ctx, "anon")
    resp = page.request.get(f"{BASE}/api/health")
    assert resp.ok
    resp = page.request.get(f"{BASE}/api/docs")
    assert resp.ok
