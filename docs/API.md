# واجهة البرمجة — Souqna REST API

- الأساس: `{PUBLIC_BASE_URL}/api` — توثيق تفاعلي (OpenAPI) على **`/api/docs`**.
- المصادقة: `Authorization: Bearer <access_token>` (Access 30 دقيقة / Refresh 30 يوماً).
- الأخطاء: JSON `{"detail": "رسالة عربية"}` مع كود HTTP مناسب. 429 عند تجاوز حدود الطلبات.
- الترقيم: الاستجابات المرقّمة بشكل `{items, total, page, size}`.

## Auth — `/api/auth`
| Method | Path | ملاحظات |
|---|---|---|
| POST | /register | `{name, phone, password}` — هاتف عراقي 07XXXXXXXXX، يعيد user + tokens (201) |
| POST | /login | `{phone, password}` — 403 إذا الحساب محظور |
| POST | /refresh | `{refresh_token}` — يعيد زوجاً جديداً |
| GET | /me 🔒 | المستخدم الحالي |

## Categories — `/api/categories`
`GET /` — الأقسام الفعّالة مرتّبة.

## Listings — `/api/listings`
| Method | Path | ملاحظات |
|---|---|---|
| GET | / | فلاتر: `q, category_id, governorate, min_price, max_price, sort (recent/price_asc/price_desc), page, size` — النشطة فقط |
| GET | /mine 🔒 | كل إعلاناتي بأي حالة |
| GET | /{id} | 404 للمخفي (إلا للمالك)؛ يزيد العدّاد لغير المالك |
| POST | / 🔒 | `{title, description, price, category_id, governorate, city?, condition, negotiable}` |
| PATCH | /{id} 🔒 | للمالك — أي حقل + `status` (active/sold/hidden) |
| DELETE | /{id} 🔒 | المالك أو المدير — يحذف الصور من التخزين |
| POST | /{id}/images 🔒 | multipart `file` — حتى 10 صور؛ إعادة ترميز آمنة |
| DELETE | /{id}/images/{image_id} 🔒 | |

## Favorites — `/api/favorites` 🔒
`GET /` (إعلانات كاملة) · `GET /ids` · `POST /{listing_id}` (يُشعر المالك) · `DELETE /{listing_id}`

## Messages — `/api/messages` 🔒
| Method | Path | ملاحظات |
|---|---|---|
| POST | / | `{listing_id, receiver_id, body}` — يُنشئ إشعاراً للمستلم |
| GET | /conversations | آخر رسالة + عدّاد غير المقروء لكل محادثة |
| GET | /conversation/{id} | للطرفين فقط (403 لغيرهما)؛ يعلّم الوارد مقروءاً |

## Notifications — `/api/notifications` 🔒
`GET /` (مرقّم) · `GET /unread-count` · `POST /read-all` · `POST /{id}/read`

## Reports — `/api/reports` 🔒
`POST /` — `{listing_id? , reported_user_id?, reason (scam|prohibited|offensive|spam|other), details?}`
- هدف واحد على الأقل؛ لا إبلاغ عن نفسك/إعلانك؛ بلاغ مفتوح واحد لكل هدف (409 للمكرر).
- بلوغ العتبة (`REPORTS_AUTO_HIDE_THRESHOLD`) يخفي الإعلان تلقائياً ويُشعر مالكه.

## Admin — `/api/admin` 🔒 (دور admin)
| Method | Path | ملاحظات |
|---|---|---|
| GET | /stats | users, listings, active_listings, messages, open_reports, banned_users |
| GET | /users | مرقّم |
| PATCH | /users/{id} | `{is_banned?, is_active?, role?}` — مسجَّل في التدقيق |
| GET | /listings | كل الحالات، مرقّم |
| PATCH | /listings/{id}/status | `{status}` — الإخفاء يُشعر المالك |
| DELETE | /listings/{id} | يحذف الصور ويُشعر المالك |
| GET | /reports?status= | قائمة البلاغات |
| POST | /reports/{id}/resolve | `{action: none/hide_listing/delete_listing/ban_user, note?}` |
| POST | /reports/{id}/dismiss | رفض البلاغ |
| POST/PATCH | /categories… | إدارة الأقسام |
| GET | /audit | سجل التدقيق مرقّماً |

## الويب (SSR) — خارج `/api`
نفس القدرات بواجهة HTML: `/` `/search` `/listings/{id}` `/login` `/register` `/post`
`/my` `/favorites` `/chat` `/notifications` `/users/{id}` ولوحة `/admin/*` —
مصادقة بكوكيز HttpOnly + حماية CSRF؛ ليست جزءاً من عقد الـ API.
