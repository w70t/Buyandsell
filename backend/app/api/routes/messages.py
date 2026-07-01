from fastapi import APIRouter, HTTPException, status
from sqlalchemy import func, select, update

from app.core.deps import CurrentUser, DbDep
from app.models import Listing, Message, User
from app.schemas.message import ConversationOut, MessageCreate, MessageOut

router = APIRouter(prefix="/messages", tags=["messages"])


def conversation_key(listing_id: int, a: int, b: int) -> str:
    low, high = (a, b) if a <= b else (b, a)
    return f"c.{listing_id}.{low}.{high}"


@router.post("", response_model=MessageOut, status_code=status.HTTP_201_CREATED)
async def send_message(payload: MessageCreate, user: CurrentUser, db: DbDep) -> Message:
    if payload.receiver_id == user.id:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "لا يمكنك مراسلة نفسك")
    listing = await db.get(Listing, payload.listing_id)
    if listing is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "الإعلان غير موجود")
    if await db.get(User, payload.receiver_id) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "المستخدم غير موجود")

    msg = Message(
        conversation_id=conversation_key(payload.listing_id, user.id, payload.receiver_id),
        listing_id=payload.listing_id,
        sender_id=user.id,
        receiver_id=payload.receiver_id,
        body=payload.body.strip(),
    )
    db.add(msg)
    await db.commit()
    await db.refresh(msg)
    return msg


@router.get("/conversations", response_model=list[ConversationOut])
async def list_conversations(user: CurrentUser, db: DbDep) -> list[ConversationOut]:
    # Latest message id per conversation this user participates in.
    latest_ids = (
        select(func.max(Message.id))
        .where((Message.sender_id == user.id) | (Message.receiver_id == user.id))
        .group_by(Message.conversation_id)
    )
    rows = await db.scalars(
        select(Message).where(Message.id.in_(latest_ids)).order_by(Message.created_at.desc())
    )
    messages = list(rows)

    result: list[ConversationOut] = []
    for m in messages:
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
        result.append(
            ConversationOut(
                conversation_id=m.conversation_id,
                listing_id=m.listing_id,
                listing_title=listing.title if listing else "",
                other_user_id=other_id,
                other_user_name=other.name if other else "",
                last_message=m.body,
                last_at=m.created_at,
                unread=unread,
            )
        )
    return result


@router.get("/conversation/{conversation_id}", response_model=list[MessageOut])
async def get_conversation(conversation_id: str, user: CurrentUser, db: DbDep) -> list[Message]:
    rows = await db.scalars(
        select(Message)
        .where(Message.conversation_id == conversation_id)
        .order_by(Message.created_at.asc())
    )
    messages = list(rows)
    # Only participants may read a thread.
    if messages and user.id not in {messages[0].sender_id, messages[0].receiver_id}:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "غير مصرح")

    # Mark inbound messages as read.
    await db.execute(
        update(Message)
        .where(
            Message.conversation_id == conversation_id,
            Message.receiver_id == user.id,
            Message.is_read.is_(False),
        )
        .values(is_read=True)
    )
    await db.commit()
    return messages
