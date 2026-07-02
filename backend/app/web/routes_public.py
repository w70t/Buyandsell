"""Public server-rendered web app (SEO-friendly, RTL Arabic)."""
from __future__ import annotations

from fastapi import APIRouter, Form, HTTPException, Query, Request, Response, UploadFile, status
from fastapi.responses import RedirectResponse
from pydantic import ValidationError
from sqlalchemy import func, or_, select
from sqlalchemy.orm import selectinload

from app.api.routes.messages import conversation_key
from app.core.config import settings
from app.core.security import hash_password, verify_password
from app.db.session import SessionLocal
from app.models import (
    Category,
    Favorite,
    Listing,
    ListingImage,
    ListingStatus,
    Message,
    Notification,
    NotificationType,
    User,
    UserRole,
)
from app.schemas.user import normalize_phone
from app.services.moderation import create_report
from app.services.notify import notify_user, telegram_admin_bg
from app.services.storage import UploadError, storage
from app.web.deps import (
    AuthedWebUser,
    CsrfCheck,
    WebUser,
    clear_auth_cookies,
    set_auth_cookies,
    verify_csrf,
)
from app.web.helpers import base_context, render

router = APIRouter(include_in_schema=False)

_EAGER = (
    selectinload(Listing.category),
    selectinload(Listing.seller),
    selectinload(Listing.images),
)
PAGE_SIZE = 12


def _redirect(url: str, response: Response | None = None) -> RedirectResponse:
    result = RedirectResponse(url, status_code=status.HTTP_303_SEE_OTHER)
    if response is not None:
        for header, value in response.raw_headers:
            if header == b"set-cookie":
                result.raw_headers.append((header, value))
    return result


async def _favorite_ids(db, user: User | None) -> set[int]:
    if user is None:
        return set()
    rows = await db.scalars(select(Favorite.listing_id).where(Favorite.user_id == user.id))
    return set(rows)


# ---- Home / browse / search ----
@router.get("/")
async def home(request: Request, response: Response, user: WebUser):
    ctx = await base_context(request, response, user)
    async with SessionLocal() as db:
        listings = list(
            await db.scalars(
                select(Listing)
                .where(Listing.status == ListingStatus.ACTIVE.value)
                .options(*_EAGER)
                .order_by(Listing.created_at.desc())
                .limit(PAGE_SIZE)
            )
        )
        ctx["fav_ids"] = await _favorite_ids(db, user)
    ctx["listings"] = listings
    return render("home.html", ctx, response)


@router.get("/search")
async def search(
    request: Request,
    response: Response,
    user: WebUser,
    q: str | None = Query(default=None, max_length=140),
    category_id: int | None = None,
    governorate: str | None = None,
    min_price: int | None = Query(default=None, ge=0),
    max_price: int | None = Query(default=None, ge=0),
    sort: str = Query(default="recent", pattern="^(recent|price_asc|price_desc)$"),
    page: int = Query(default=1, ge=1),
):
    ctx = await base_context(request, response, user)
    conditions = [Listing.status == ListingStatus.ACTIVE.value]
    if q:
        like = f"%{q.strip()}%"
        conditions.append(or_(Listing.title.ilike(like), Listing.description.ilike(like)))
    if category_id:
        conditions.append(Listing.category_id == category_id)
    if governorate:
        conditions.append(Listing.governorate == governorate)
    if min_price is not None:
        conditions.append(Listing.price >= min_price)
    if max_price is not None:
        conditions.append(Listing.price <= max_price)
    order = {
        "recent": Listing.created_at.desc(),
        "price_asc": Listing.price.asc(),
        "price_desc": Listing.price.desc(),
    }[sort]
    async with SessionLocal() as db:
        total = await db.scalar(select(func.count()).select_from(Listing).where(*conditions)) or 0
        listings = list(
            await db.scalars(
                select(Listing)
                .where(*conditions)
                .options(*_EAGER)
                .order_by(order)
                .offset((page - 1) * PAGE_SIZE)
                .limit(PAGE_SIZE)
            )
        )
        ctx["fav_ids"] = await _favorite_ids(db, user)
    ctx.update(
        listings=listings,
        total=total,
        page=page,
        pages=(total + PAGE_SIZE - 1) // PAGE_SIZE,
        q=q or "",
        category_id=category_id,
        governorate=governorate or "",
        min_price=min_price,
        max_price=max_price,
        sort=sort,
    )
    return render("search.html", ctx, response)


@router.get("/listings/{listing_id}")
async def listing_detail(request: Request, response: Response, user: WebUser, listing_id: int):
    ctx = await base_context(request, response, user)
    async with SessionLocal() as db:
        listing = await db.scalar(
            select(Listing).where(Listing.id == listing_id).options(*_EAGER)
        )
        if listing is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "الإعلان غير موجود")
        is_owner = user is not None and user.id == listing.seller_id
        is_admin = user is not None and user.role == UserRole.ADMIN.value
        if listing.status == ListingStatus.HIDDEN.value and not (is_owner or is_admin):
            raise HTTPException(status.HTTP_404_NOT_FOUND, "الإعلان غير موجود")
        if not is_owner:
            listing.views += 1
            await db.commit()
        ctx["fav_ids"] = await _favorite_ids(db, user)
    ctx.update(listing=listing, is_owner=is_owner)
    return render("listing_detail.html", ctx, response)


@router.get("/users/{user_id}")
async def seller_page(request: Request, response: Response, user: WebUser, user_id: int):
    ctx = await base_context(request, response, user)
    async with SessionLocal() as db:
        seller = await db.get(User, user_id)
        if seller is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "المستخدم غير موجود")
        listings = list(
            await db.scalars(
                select(Listing)
                .where(Listing.seller_id == user_id, Listing.status == ListingStatus.ACTIVE.value)
                .options(*_EAGER)
                .order_by(Listing.created_at.desc())
            )
        )
        ctx["fav_ids"] = await _favorite_ids(db, user)
    ctx.update(seller=seller, listings=listings)
    return render("seller.html", ctx, response)


# ---- Auth ----
@router.get("/login")
async def login_page(request: Request, response: Response, user: WebUser, next: str = "/"):
    if user is not None:
        return _redirect(next)
    ctx = await base_context(request, response, user)
    ctx.update(error=None, next=next, phone="")
    return render("login.html", ctx, response)


@router.post("/login")
async def login_submit(
    request: Request,
    response: Response,
    phone: str = Form(...),
    password: str = Form(...),
    next: str = Form(default="/"),
    _=CsrfCheck,
):
    ctx_user = None
    error = None
    try:
        phone_norm = normalize_phone(phone)
    except ValueError:
        phone_norm, error = "", "رقم هاتف عراقي غير صالح"
    if not error:
        async with SessionLocal() as db:
            found = await db.scalar(select(User).where(User.phone == phone_norm))
            if found is None or not verify_password(password, found.password_hash):
                error = "رقم الهاتف أو كلمة المرور غير صحيحة"
            elif found.is_banned or not found.is_active:
                error = "الحساب موقوف"
            else:
                ctx_user = found
    if error:
        ctx = await base_context(request, response, None)
        ctx.update(error=error, next=next, phone=phone)
        return render("login.html", ctx, response, status_code=400)
    dest = next if next.startswith("/") else "/"
    result = _redirect(dest)
    set_auth_cookies(result, ctx_user)
    return result


@router.get("/register")
async def register_page(request: Request, response: Response, user: WebUser):
    if user is not None:
        return _redirect("/")
    ctx = await base_context(request, response, user)
    ctx.update(error=None, name="", phone="")
    return render("register.html", ctx, response)


@router.post("/register")
async def register_submit(
    request: Request,
    response: Response,
    name: str = Form(...),
    phone: str = Form(...),
    password: str = Form(...),
    _=CsrfCheck,
):
    error = None
    name = name.strip()
    if len(name) < 2:
        error = "الاسم قصير جداً"
    try:
        phone_norm = normalize_phone(phone)
    except ValueError:
        phone_norm, error = "", error or "رقم هاتف عراقي غير صالح (مثال: 07701234567)"
    if not error and len(password) < 6:
        error = "كلمة المرور يجب أن تكون 6 أحرف على الأقل"
    new_user = None
    if not error:
        async with SessionLocal() as db:
            if await db.scalar(select(User).where(User.phone == phone_norm)):
                error = "رقم الهاتف مسجّل مسبقاً"
            else:
                new_user = User(
                    name=name,
                    phone=phone_norm,
                    password_hash=hash_password(password),
                    role=UserRole.USER.value,
                )
                db.add(new_user)
                await db.commit()
                await db.refresh(new_user)
    if error:
        ctx = await base_context(request, response, None)
        ctx.update(error=error, name=name, phone=phone)
        return render("register.html", ctx, response, status_code=400)
    telegram_admin_bg(f"👤 مستخدم جديد: {new_user.name} — Souqna")
    result = _redirect("/")
    set_auth_cookies(result, new_user)
    return result


@router.post("/logout")
async def logout(_=CsrfCheck):
    result = _redirect("/")
    clear_auth_cookies(result)
    return result


# ---- Post / manage listings ----
@router.get("/post")
async def post_page(request: Request, response: Response, user: AuthedWebUser):
    ctx = await base_context(request, response, user)
    ctx.update(error=None, listing=None)
    return render("post_listing.html", ctx, response)


async def _save_listing_images(db, listing: Listing, images: list[UploadFile]) -> str | None:
    position = max((img.position for img in listing.images), default=-1) + 1
    for upload in images[:10]:
        raw = await upload.read()
        if not raw:
            continue
        try:
            key = storage.save_image(raw, folder="listings")
        except UploadError as exc:
            return str(exc)
        db.add(
            ListingImage(
                listing_id=listing.id, key=key, url=storage.public_url(key), position=position
            )
        )
        position += 1
    return None


@router.post("/post")
async def post_submit(
    request: Request,
    response: Response,
    user: AuthedWebUser,
    title: str = Form(...),
    description: str = Form(...),
    price: int = Form(ge=0),
    category_id: int = Form(...),
    governorate: str = Form(...),
    city: str = Form(default=""),
    condition: str = Form(default="used"),
    negotiable: bool = Form(default=False),
    images: list[UploadFile] = [],
    _=CsrfCheck,
):
    error = None
    if len(title.strip()) < 3:
        error = "العنوان قصير جداً"
    elif len(description.strip()) < 5:
        error = "الوصف قصير جداً"
    elif condition not in ("new", "used"):
        error = "حالة غير صالحة"
    listing = None
    if not error:
        async with SessionLocal() as db:
            if await db.get(Category, category_id) is None:
                error = "القسم غير موجود"
            else:
                listing = Listing(
                    title=title.strip(),
                    description=description.strip(),
                    price=price,
                    negotiable=negotiable,
                    condition=condition,
                    category_id=category_id,
                    governorate=governorate,
                    city=city.strip(),
                    seller_id=user.id,
                )
                db.add(listing)
                await db.flush()
                await db.refresh(listing, ["images"])
                error = await _save_listing_images(db, listing, images)
                if error:
                    await db.rollback()
                    listing = None
                else:
                    await db.commit()
                    await db.refresh(listing)
    if error:
        ctx = await base_context(request, response, user)
        ctx.update(error=error, listing=None)
        return render("post_listing.html", ctx, response, status_code=400)
    telegram_admin_bg(f"📋 إعلان جديد #{listing.id}: {listing.title} — Souqna")
    return _redirect(f"/listings/{listing.id}", response)


@router.get("/listings/{listing_id}/edit")
async def edit_page(request: Request, response: Response, user: AuthedWebUser, listing_id: int):
    ctx = await base_context(request, response, user)
    async with SessionLocal() as db:
        listing = await db.scalar(select(Listing).where(Listing.id == listing_id).options(*_EAGER))
    if listing is None or listing.seller_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "الإعلان غير موجود")
    ctx.update(error=None, listing=listing)
    return render("post_listing.html", ctx, response)


@router.post("/listings/{listing_id}/edit")
async def edit_submit(
    request: Request,
    response: Response,
    user: AuthedWebUser,
    listing_id: int,
    title: str = Form(...),
    description: str = Form(...),
    price: int = Form(ge=0),
    category_id: int = Form(...),
    governorate: str = Form(...),
    city: str = Form(default=""),
    condition: str = Form(default="used"),
    negotiable: bool = Form(default=False),
    images: list[UploadFile] = [],
    _=CsrfCheck,
):
    async with SessionLocal() as db:
        listing = await db.scalar(select(Listing).where(Listing.id == listing_id).options(*_EAGER))
        if listing is None or listing.seller_id != user.id:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "الإعلان غير موجود")
        listing.title = title.strip()
        listing.description = description.strip()
        listing.price = price
        listing.category_id = category_id
        listing.governorate = governorate
        listing.city = city.strip()
        listing.condition = condition if condition in ("new", "used") else "used"
        listing.negotiable = negotiable
        error = await _save_listing_images(db, listing, images)
        if error:
            await db.rollback()
            ctx = await base_context(request, response, user)
            ctx.update(error=error, listing=listing)
            return render("post_listing.html", ctx, response, status_code=400)
        await db.commit()
    return _redirect(f"/listings/{listing_id}", response)


@router.post("/listings/{listing_id}/status")
async def set_status(
    response: Response,
    user: AuthedWebUser,
    listing_id: int,
    new_status: str = Form(alias="status"),
    _=CsrfCheck,
):
    if new_status not in ("active", "sold", "hidden"):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "حالة غير صالحة")
    async with SessionLocal() as db:
        listing = await db.get(Listing, listing_id)
        if listing is None or listing.seller_id != user.id:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "الإعلان غير موجود")
        listing.status = new_status
        await db.commit()
    return _redirect(f"/listings/{listing_id}", response)


@router.post("/listings/{listing_id}/delete")
async def delete_listing_web(
    response: Response, user: AuthedWebUser, listing_id: int, _=CsrfCheck
):
    async with SessionLocal() as db:
        listing = await db.scalar(
            select(Listing).where(Listing.id == listing_id).options(selectinload(Listing.images))
        )
        if listing is None or (listing.seller_id != user.id and not user.is_admin):
            raise HTTPException(status.HTTP_404_NOT_FOUND, "الإعلان غير موجود")
        for img in listing.images:
            storage.delete(img.key)
        await db.delete(listing)
        await db.commit()
    return _redirect("/my", response)


@router.get("/my")
async def my_listings(request: Request, response: Response, user: AuthedWebUser):
    ctx = await base_context(request, response, user)
    async with SessionLocal() as db:
        listings = list(
            await db.scalars(
                select(Listing)
                .where(Listing.seller_id == user.id)
                .options(*_EAGER)
                .order_by(Listing.created_at.desc())
            )
        )
        ctx["fav_ids"] = await _favorite_ids(db, user)
    ctx["listings"] = listings
    return render("my_listings.html", ctx, response)


# ---- Favorites ----
@router.get("/favorites")
async def favorites_page(request: Request, response: Response, user: AuthedWebUser):
    ctx = await base_context(request, response, user)
    async with SessionLocal() as db:
        listings = list(
            await db.scalars(
                select(Listing)
                .join(Favorite, Favorite.listing_id == Listing.id)
                .where(Favorite.user_id == user.id)
                .options(*_EAGER)
                .order_by(Favorite.created_at.desc())
            )
        )
    ctx.update(listings=listings, fav_ids={l.id for l in listings})
    return render("favorites.html", ctx, response)


@router.post("/favorites/{listing_id}/toggle")
async def toggle_favorite(
    request: Request, response: Response, user: AuthedWebUser, listing_id: int, _=CsrfCheck
):
    async with SessionLocal() as db:
        listing = await db.get(Listing, listing_id)
        if listing is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "الإعلان غير موجود")
        fav = await db.get(Favorite, {"user_id": user.id, "listing_id": listing_id})
        if fav is None:
            db.add(Favorite(user_id=user.id, listing_id=listing_id))
            if listing.seller_id != user.id:
                notify_user(
                    db,
                    listing.seller_id,
                    NotificationType.FAVORITE.value,
                    "أُضيف إعلانك إلى المفضلة",
                    f"أضاف {user.name} إعلانك «{listing.title}» إلى مفضلته.",
                    f"/listings/{listing.id}",
                )
        else:
            await db.delete(fav)
        await db.commit()
    back = request.headers.get("referer") or f"/listings/{listing_id}"
    return _redirect(back, response)


# ---- Chat ----
@router.get("/chat")
async def conversations_page(request: Request, response: Response, user: AuthedWebUser):
    ctx = await base_context(request, response, user)
    async with SessionLocal() as db:
        latest_ids = (
            select(func.max(Message.id))
            .where((Message.sender_id == user.id) | (Message.receiver_id == user.id))
            .group_by(Message.conversation_id)
        )
        rows = list(
            await db.scalars(
                select(Message).where(Message.id.in_(latest_ids)).order_by(Message.created_at.desc())
            )
        )
        conversations = []
        for m in rows:
            other_id = m.receiver_id if m.sender_id == user.id else m.sender_id
            other = await db.get(User, other_id)
            listing = await db.get(Listing, m.listing_id)
            unread = await db.scalar(
                select(func.count())
                .select_from(Message)
                .where(
                    Message.conversation_id == m.conversation_id,
                    Message.receiver_id == user.id,
                    Message.is_read.is_(False),
                )
            ) or 0
            conversations.append(
                {
                    "id": m.conversation_id,
                    "listing_title": listing.title if listing else "إعلان محذوف",
                    "other_name": other.name if other else "مستخدم",
                    "last": m.body,
                    "at": m.created_at,
                    "unread": unread,
                }
            )
    ctx["conversations"] = conversations
    return render("conversations.html", ctx, response)


@router.get("/chat/{conversation_id}")
async def chat_page(
    request: Request, response: Response, user: AuthedWebUser, conversation_id: str
):
    ctx = await base_context(request, response, user)
    async with SessionLocal() as db:
        messages = list(
            await db.scalars(
                select(Message)
                .where(Message.conversation_id == conversation_id)
                .order_by(Message.created_at.asc())
            )
        )
        if messages and user.id not in {messages[0].sender_id, messages[0].receiver_id}:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "غير مصرح")
        other_id = None
        listing = None
        if messages:
            first = messages[0]
            other_id = first.receiver_id if first.sender_id == user.id else first.sender_id
            listing = await db.get(Listing, first.listing_id)
            for m in messages:
                if m.receiver_id == user.id and not m.is_read:
                    m.is_read = True
            await db.commit()
        other = await db.get(User, other_id) if other_id else None
    ctx.update(
        conversation_id=conversation_id,
        messages=messages,
        other=other,
        listing=listing,
    )
    return render("chat.html", ctx, response)


@router.post("/listings/{listing_id}/message")
async def start_conversation(
    response: Response,
    user: AuthedWebUser,
    listing_id: int,
    body: str = Form(min_length=1, max_length=2000),
    _=CsrfCheck,
):
    async with SessionLocal() as db:
        listing = await db.get(Listing, listing_id)
        if listing is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "الإعلان غير موجود")
        if listing.seller_id == user.id:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "لا يمكنك مراسلة نفسك")
        cid = conversation_key(listing_id, user.id, listing.seller_id)
        db.add(
            Message(
                conversation_id=cid,
                listing_id=listing_id,
                sender_id=user.id,
                receiver_id=listing.seller_id,
                body=body.strip(),
            )
        )
        notify_user(
            db,
            listing.seller_id,
            NotificationType.MESSAGE.value,
            f"رسالة جديدة من {user.name}",
            body.strip()[:120],
            f"/chat/{cid}",
        )
        await db.commit()
    return _redirect(f"/chat/{cid}", response)


@router.post("/chat/{conversation_id}/send")
async def send_in_conversation(
    response: Response,
    user: AuthedWebUser,
    conversation_id: str,
    body: str = Form(min_length=1, max_length=2000),
    _=CsrfCheck,
):
    async with SessionLocal() as db:
        first = await db.scalar(
            select(Message)
            .where(Message.conversation_id == conversation_id)
            .order_by(Message.id.asc())
            .limit(1)
        )
        if first is None or user.id not in {first.sender_id, first.receiver_id}:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "غير مصرح")
        receiver_id = first.receiver_id if first.sender_id == user.id else first.sender_id
        db.add(
            Message(
                conversation_id=conversation_id,
                listing_id=first.listing_id,
                sender_id=user.id,
                receiver_id=receiver_id,
                body=body.strip(),
            )
        )
        notify_user(
            db,
            receiver_id,
            NotificationType.MESSAGE.value,
            f"رسالة جديدة من {user.name}",
            body.strip()[:120],
            f"/chat/{conversation_id}",
        )
        await db.commit()
    return _redirect(f"/chat/{conversation_id}", response)


# ---- Notifications ----
@router.get("/notifications")
async def notifications_page(request: Request, response: Response, user: AuthedWebUser):
    ctx = await base_context(request, response, user)
    async with SessionLocal() as db:
        items = list(
            await db.scalars(
                select(Notification)
                .where(Notification.user_id == user.id)
                .order_by(Notification.created_at.desc(), Notification.id.desc())
                .limit(50)
            )
        )
    ctx["notifications"] = items
    return render("notifications.html", ctx, response)


@router.post("/notifications/read-all")
async def notifications_read_all(response: Response, user: AuthedWebUser, _=CsrfCheck):
    from sqlalchemy import update as sa_update

    async with SessionLocal() as db:
        await db.execute(
            sa_update(Notification)
            .where(Notification.user_id == user.id, Notification.is_read.is_(False))
            .values(is_read=True)
        )
        await db.commit()
    return _redirect("/notifications", response)


# ---- Reports ----
@router.post("/report")
async def report_submit(
    request: Request,
    response: Response,
    user: AuthedWebUser,
    reason: str = Form(...),
    details: str = Form(default=""),
    listing_id: int | None = Form(default=None),
    reported_user_id: int | None = Form(default=None),
    _=CsrfCheck,
):
    if reason not in ("scam", "prohibited", "offensive", "spam", "other"):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "سبب غير صالح")
    async with SessionLocal() as db:
        await create_report(db, user, listing_id, reported_user_id, reason, details)
    back = request.headers.get("referer") or "/"
    return _redirect(back + ("&" if "?" in back else "?") + "reported=1", response)
