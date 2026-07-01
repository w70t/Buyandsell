from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class MessageCreate(BaseModel):
    listing_id: int
    receiver_id: int
    body: str = Field(min_length=1, max_length=2000)


class MessageOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    conversation_id: str
    listing_id: int
    sender_id: int
    receiver_id: int
    body: str
    is_read: bool
    created_at: datetime


class ConversationOut(BaseModel):
    conversation_id: str
    listing_id: int
    listing_title: str
    other_user_id: int
    other_user_name: str
    last_message: str
    last_at: datetime
    unread: int
