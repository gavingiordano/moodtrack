from contextlib import asynccontextmanager

import routes
from database import create_db_and_tables
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles


@asynccontextmanager
async def lifespan(app: FastAPI):
    create_db_and_tables()
    yield

app = FastAPI(lifespan=lifespan)

app.mount("/static", StaticFiles(directory="static"), name="static")
app.include_router(routes.router)
