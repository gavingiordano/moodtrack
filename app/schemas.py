from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class UserCreate(BaseModel):
    name: str
    username: str
    password: str


class UserRead(BaseModel):
    id: int
    name: str
    username: str


class EntryCreate(BaseModel):
    mood_score: int = Field(..., ge=1, le=5)
    comment: Optional[str] = None


class EntryRead(BaseModel):
    id: int
    mood_score: int
    comment: Optional[str]
    created_at: datetime
