from pathlib import Path
from urllib.parse import quote

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

from app.api.router import api_router
from app.core.config import settings
from app.core.logging import configure_logging, logger
from app.core.rate_limit import limiter
from app.web import routes_admin, routes_public
from app.web.deps import LoginRequired
from app.web.helpers import STATIC_DIR

configure_logging()

app = FastAPI(
    title=f"{settings.app_name} API",
    version="1.0.0",
    docs_url="/api/docs",
    openapi_url="/api/openapi.json",
)

# Rate limiting
app.state.limiter = limiter
app.add_middleware(SlowAPIMiddleware)


@app.exception_handler(RateLimitExceeded)
async def rate_limit_handler(request: Request, exc: RateLimitExceeded) -> JSONResponse:
    return JSONResponse(status_code=429, content={"detail": "طلبات كثيرة، حاول لاحقاً"})


# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Serve uploaded media directly when using local storage.
if settings.storage_backend.lower() == "local":
    Path(settings.upload_dir).mkdir(parents=True, exist_ok=True)
    app.mount("/media", StaticFiles(directory=settings.upload_dir), name="media")

app.include_router(api_router, prefix="/api")

# Server-rendered web app (public site + admin dashboard) + its static assets.
app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")
app.include_router(routes_admin.router)
app.include_router(routes_public.router)


@app.exception_handler(LoginRequired)
async def login_required_handler(request: Request, exc: LoginRequired) -> RedirectResponse:
    return RedirectResponse(f"/login?next={quote(exc.next_path)}", status_code=303)


@app.on_event("startup")
async def _startup() -> None:
    logger.info("%s API starting (env=%s, storage=%s)", settings.app_name, settings.app_env, settings.storage_backend)
