import os
from typing import Optional

from database import get_session
from dotenv import load_dotenv
from fastapi import Depends, HTTPException, Request, status
from itsdangerous import BadSignature, SignatureExpired, URLSafeTimedSerializer
from models import User
from passlib.context import CryptContext
from sqlmodel import Session, select

load_dotenv()

SECRET_KEY = os.environ["SECRET_KEY"]

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

serializer = URLSafeTimedSerializer(
    SECRET_KEY,
    salt="moodtrack-session"
)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)


def authenticate_user(username: str, password: str, session: Session) -> Optional[User]:
    user = session.exec(select(User).where(User.username == username)).first()
    if not user or not verify_password(password, user.hashed_password):
        return None
    return user


def create_session_token(user_id: int) -> str:
    return serializer.dumps(user_id)


def verify_session_token(token: str) -> int | None:
    try:
        return serializer.loads(token, max_age=3600)
    except (BadSignature, SignatureExpired):
        return None


def get_current_user(
    request: Request,
    session: Session = Depends(get_session)
) -> User:
    token = request.cookies.get("session")
    if not token:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)

    user_id = verify_session_token(token)
    if not user_id:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)

    user = session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)

    return user
