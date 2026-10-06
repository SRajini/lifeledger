from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.db import Base, engine
from app.routers import auth, bills, claims, retail, finance, consent

Base.metadata.create_all(bind=engine)

app = FastAPI(title="LifeLedger API", version="0.1.0")
app.add_middleware(
    CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"]
)

for r in (auth, bills, claims, retail, finance, consent):
    app.include_router(r.router)


@app.get("/")
def health():
    return {"app": "LifeLedger", "status": "ok"}
