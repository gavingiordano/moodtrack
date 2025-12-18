from datetime import timedelta
from typing import Optional

import auth
from database import get_session
from fastapi import APIRouter, Depends, Form, HTTPException, Request, status
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from models import Entry, User
from sqlmodel import Session, select

router = APIRouter()

templates = Jinja2Templates(directory="templates")


# Authentication Routes

@router.get("/login", response_class=HTMLResponse)
def login_page(request: Request) -> HTMLResponse:
    return templates.TemplateResponse(
        "login.html",
        {"request": request}
    )


@router.post("/login")
def login_user(request: Request, username: str = Form(...), password: str = Form(...), session: Session = Depends(get_session)):
    user = auth.authenticate_user(username, password, session)
    if not user:
        return templates.TemplateResponse(
            "login.html",
            {"request": request, "error": "Invalid username or password"},
            status_code=401
        )
    token = auth.create_session_token(user.id)
    response = RedirectResponse("/", status_code=303)
    response.set_cookie("session", token, httponly=True,
                        secure=False, samesite="lax", max_age=3600)
    response.headers["HX-Redirect"] = "/"
    return response


@router.get("/signup", response_class=HTMLResponse)
async def signup_page(request: Request) -> HTMLResponse:
    return templates.TemplateResponse(
        "signup.html",
        {"request": request}
    )


@router.post("/signup")
def signup_user(request: Request, name: str = Form(...), username: str = Form(...), password: str = Form(...), session: Session = Depends(get_session)):
    if session.exec(select(User).where(User.username == username)).first():
        return templates.TemplateResponse(
            "signup.html",
            {"request": request, "error": "Username already taken"},
            status_code=400
        )
    user = User(name=name, username=username,
                hashed_password=auth.get_password_hash(password))
    session.add(user)
    session.commit()
    session.refresh(user)
    token = auth.create_session_token(user.id)
    response = RedirectResponse("/", status_code=303)
    response.set_cookie("session", token, httponly=True,
                        secure=False, samesite="lax", max_age=3600)
    response.headers["HX-Redirect"] = "/"
    return response


@router.post("/logout", response_class=HTMLResponse)
async def logout():
    response = RedirectResponse(
        url="/login", status_code=status.HTTP_302_FOUND)
    response.delete_cookie("session")
    return response


# Entry Routes

@router.get("/", response_class=HTMLResponse)
async def home(request: Request):
    token = request.cookies.get("session")
    if token and auth.verify_session_token(token):
        return RedirectResponse(url="/dashboard", status_code=status.HTTP_302_FOUND)
    else:
        return RedirectResponse(url="/login", status_code=status.HTTP_302_FOUND)


@router.get("/dashboard", response_class=HTMLResponse)
async def dashboard(request: Request, current_user: User = Depends(auth.get_current_user), session: Session = Depends(get_session)):
    return templates.TemplateResponse(
        "dashboard.html",
        {"request": request, "user": current_user}
    )


@router.post("/entries")
def create_entry(request: Request, mood_score: int = Form(...), comment: Optional[str] = Form(None), session: Session = Depends(get_session), current_user: User = Depends(auth.get_current_user)):
    new_entry = Entry(mood_score=mood_score, comment=comment,
                      user_id=current_user.id)
    session.add(new_entry)
    session.commit()
    session.refresh(new_entry)
    return templates.TemplateResponse(
        "fragments/entry.html",
        {"request": request, "entry": new_entry}
    )


@router.put("/entries/{entry_id}")
def update_entry(request: Request, entry_id: int, mood_score: int = Form(...), comment: Optional[str] = Form(None), session: Session = Depends(get_session), current_user: User = Depends(auth.get_current_user)):
    entry = session.exec(select(Entry).where(
        Entry.id == entry_id, Entry.user_id == current_user.id)).first()
    if not entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Entry not found",
        )
    entry.mood_score = mood_score
    entry.comment = comment
    session.add(entry)
    session.commit()
    session.refresh(entry)
    return templates.TemplateResponse(
        "fragments/entry.html",
        {"request": request, "entry": entry}
    )


@router.delete("/entries/{entry_id}")
def delete_entry(entry_id: int, session: Session = Depends(get_session), current_user: User = Depends(auth.get_current_user)):
    entry = session.exec(select(Entry).where(
        Entry.id == entry_id, Entry.user_id == current_user.id)).first()
    if not entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Entry not found",
        )
    session.delete(entry)
    session.commit()
    return HTMLResponse(content="", status_code=200)


@router.get("/entries")
def list_entries(request: Request, session: Session = Depends(get_session), current_user: User = Depends(auth.get_current_user)):
    entries = session.exec(select(Entry).where(
        Entry.user_id == current_user.id)).all()
    return templates.TemplateResponse(
        "fragments/entries_list.html",
        {"request": request, "entries": entries}
    )


@router.get("/entries/{entry_id}/edit")
def edit_entry_form(request: Request, entry_id: int, session: Session = Depends(get_session), current_user: User = Depends(auth.get_current_user)):
    entry = session.exec(select(Entry).where(
        Entry.id == entry_id, Entry.user_id == current_user.id)).first()
    if not entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Entry not found",
        )
    return templates.TemplateResponse(
        "fragments/entry_edit.html",
        {"request": request, "entry": entry}
    )


@router.get("/entries/{entry_id}/cancel")
def cancel_edit(request: Request, entry_id: int, session: Session = Depends(get_session), current_user: User = Depends(auth.get_current_user)):
    entry = session.exec(select(Entry).where(
        Entry.id == entry_id, Entry.user_id == current_user.id)).first()
    if not entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Entry not found",
        )
    return templates.TemplateResponse(
        "fragments/entry.html",
        {"request": request, "entry": entry}
    )
