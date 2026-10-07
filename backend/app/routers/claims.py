from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db import get_db
from app.deps import current_user
from app.models import Bill, Claim, User
from app.schemas import ClaimCheckRequest
from app.services.claim_checker import check_claim

router = APIRouter(prefix="/claims", tags=["claims"])


@router.post("/check")
def check(req: ClaimCheckRequest, db: Session = Depends(get_db), user: User = Depends(current_user)):
    bill = db.query(Bill).filter_by(id=req.bill_id, user_id=user.id).first()
    if not bill:
        raise HTTPException(404, "Bill not found")
    result = check_claim(bill, req)
    db.add(Claim(user_id=user.id, bill_id=bill.id, risk_score=result["risk_score"], result=result))
    db.commit()
    return result
