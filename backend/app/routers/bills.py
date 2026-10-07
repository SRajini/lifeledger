from datetime import date
from fastapi import APIRouter, Depends, UploadFile, File
from sqlalchemy.orm import Session
from app.db import get_db
from app.deps import current_user
from app.models import Bill, User
from app.services import ocr_service, llm_parser, overbilling, forecast

router = APIRouter(prefix="/bills", tags=["bills"])


def _out(b: Bill) -> dict:
    return {"id": b.id, "provider": b.provider, "bill_date": b.bill_date.isoformat(), "category": b.category,
            "total": b.total, "items": b.items, "flags": b.flags}


@router.post("/upload")
async def upload_bill(file: UploadFile = File(...), db: Session = Depends(get_db), user: User = Depends(current_user)):
    data = await file.read()
    text = ocr_service.extract_text(data, file.filename or "")
    parsed = llm_parser.parse_bill(text)
    flags = overbilling.check_items(parsed["items"])
    bill = Bill(user_id=user.id, provider=parsed["provider"], bill_date=date.fromisoformat(parsed["bill_date"]),
                category=parsed["category"], total=parsed["total"], items=parsed["items"], flags=flags, raw_text=text)
    db.add(bill); db.commit(); db.refresh(bill)
    return _out(bill)


@router.get("")
def list_bills(db: Session = Depends(get_db), user: User = Depends(current_user)):
    bills = db.query(Bill).filter_by(user_id=user.id).order_by(Bill.bill_date.desc()).all()
    return [_out(b) for b in bills]


@router.get("/forecast")
def get_forecast(db: Session = Depends(get_db), user: User = Depends(current_user)):
    return forecast.forecast_next_month(db.query(Bill).filter_by(user_id=user.id).all())
