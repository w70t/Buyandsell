from fastapi import APIRouter

from app.api.routes import (
    admin,
    auth,
    categories,
    favorites,
    health,
    listings,
    messages,
    notifications,
    reports,
)

api_router = APIRouter()
api_router.include_router(health.router)
api_router.include_router(auth.router)
api_router.include_router(categories.router)
api_router.include_router(listings.router)
api_router.include_router(favorites.router)
api_router.include_router(messages.router)
api_router.include_router(notifications.router)
api_router.include_router(reports.router)
api_router.include_router(admin.router)
