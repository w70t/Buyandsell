from app.models import Listing
from app.schemas.category import CategoryOut
from app.schemas.listing import ListingImageOut, ListingOut
from app.schemas.user import UserPublic
from app.services.storage import storage


def listing_to_out(listing: Listing) -> ListingOut:
    """Build the API representation, rebuilding image URLs from their storage
    keys so they stay correct even after moving Pi -> VPS (PUBLIC_BASE_URL change).
    """
    return ListingOut(
        id=listing.id,
        title=listing.title,
        description=listing.description,
        price=listing.price,
        currency=listing.currency,
        negotiable=listing.negotiable,
        condition=listing.condition,
        governorate=listing.governorate,
        city=listing.city,
        status=listing.status,
        views=listing.views,
        created_at=listing.created_at,
        category=CategoryOut.model_validate(listing.category),
        seller=UserPublic.model_validate(listing.seller),
        images=[
            ListingImageOut(id=img.id, url=storage.public_url(img.key), position=img.position)
            for img in listing.images
        ],
    )
