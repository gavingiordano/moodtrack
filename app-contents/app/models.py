from datetime import datetime, timezone
from typing import Optional

from sqlmodel import Field, SQLModel


class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    username: str = Field(index=True, unique=True)
    hashed_password: str


class Entry(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    mood_score: int = Field(ge=1, le=5)
    comment: Optional[str] = Field(default=None)
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc))
    user_id: int = Field(foreign_key="user.id")
