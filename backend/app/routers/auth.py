from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db import get_db
from app.deps import create_token
from app.models import User, SavingsPot, Consent
from app.schemas import OtpRequest, OtpVerify

router = APIRouter(prefix="/auth", tags=["auth"])
DEMO_OTP = "123456"  # replace with an SMS provider in production


@router.post("/send-otp")
def send_otp(req: OtpRequest):
    return {"message": "OTP sent", "demo_otp": DEMO_OTP}


@router.post("/verify-otp")
def verify_otp(req: OtpVerify, db: Session = Depends(get_db)):
    if req.otp != DEMO_OTP:
        raise HTTPException(400, "Wrong OTP")
    user = db.query(User).filter_by(phone=req.phone).first()
    if not user:
        user = User(phone=req.phone)
        db.add(user); db.flush()
        db.add(SavingsPot(user_id=user.id))
        for partner, dtype in (("bank", "bills"), ("bank", "credit_score"),
                               ("insurer", "bills"), ("pharmacy", "purchases")):
            db.add(Consent(user_id=user.id, partner=partner, data_type=dtype, allowed=False))
        db.commit()
    return {"token": create_token(user.id), "user_id": user.id}
