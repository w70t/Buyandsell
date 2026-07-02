from slowapi import Limiter
from slowapi.util import get_remote_address

from app.core.config import settings

# Keyed by client IP. Behind Nginx/Cloudflare the real IP arrives in
# X-Forwarded-For; get_remote_address reads request.client which Uvicorn
# populates from proxy headers when --proxy-headers is enabled (see entrypoint).
#
# Counters live in process memory by default (fine for a single worker on the
# Raspberry Pi). Set REDIS_URL to share counters across multiple workers/hosts
# when scaling on a VPS — no code change needed.
limiter = Limiter(
    key_func=get_remote_address,
    default_limits=[settings.rate_limit_default],
    storage_uri=settings.redis_url or "memory://",
)
