from typing import Optional

from fastapi import Depends
from passlib.context import CryptContext
from sqlmodel import Session, select

from projects.project.moodtrack.app.models import User

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)


def authenticate_user(username: str, password: str, session: Session) -> Optional[User]:
    user = session.exec(select(User).where(User.username == username))
    if not user:
        return None
    if not verify_password(password, user):
        return None
    return user
