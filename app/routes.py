from datetime import timedelta

import auth
from database import get_session
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from models import Entry, User
from schemas import EntryCreate, EntryRead, Token, UserCreate, UserRead
from sqlmodel import Session, select

router = APIRouter()


# Authentication Routes

@router.post("/login", response_model=Token)
def login_user(form_data: OAuth2PasswordRequestForm = Depends(), session: Session = Depends(get_session)):
    user = auth.authenticate_user(
        form_data.username, form_data.password, session)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}


@router.post("/signup", response_model=UserRead)
def signup_user(user_data: UserCreate, session: Session = Depends(get_session)):
    existing_user = session.exec(select(User).where(
        User.username == user_data.username)).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already taken"
        )
    hashed_password = auth.get_password_hash(user_data.password)
    new_user = User(name=user_data.name, username=user_data.username,
                    hashed_password=hashed_password)
    session.add(new_user)
    session.commit()
    session.refresh(new_user)
    return new_user


# Entry Routes

@router.post("/entries", response_model=EntryRead)
def create_entry(entry_data: EntryCreate, session: Session = Depends(get_session), current_user: User = Depends(auth.get_current_user)):
    new_entry = Entry(mood_score=entry_data.mood_score,
                      comment=entry_data.comment, user_id=current_user.id)
    session.add(new_entry)
    session.commit()
    session.refresh(new_entry)
    return new_entry


@router.put("/entries/{entry_id}", response_model=EntryRead)
def update_entry(entry_id: int, entry_data: EntryCreate, session: Session = Depends(get_session), current_user: User = Depends(auth.get_current_user)):
    entry = session.exec(select(Entry).where(
        Entry.id == entry_id, Entry.user_id == current_user.id)).first()
    if not entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Entry not found",
        )
    entry.mood_score = entry_data.mood_score
    entry.comment = entry_data.comment
    session.add(entry)
    session.commit()
    session.refresh(entry)
    return entry
