from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db import get_db
from app.deps import current_user
from app.models import Consent, User
from app.schemas import ConsentUpdate

router = APIRouter(prefix="/consent", tags=["consent"])


@router.get("")
def get_consent(db: Session = Depends(get_db), user: User = Depends(current_user)):
    rows = db.query(Consent).filter_by(user_id=user.id).all()
    return [{"partner": r.partner, "data_type": r.data_type, "allowed": r.allowed} for r in rows]


@router.put("")
def update_consent(req: ConsentUpdate, db: Session = Depends(get_db), user: User = Depends(current_user)):
    for item in req.items:
        row = db.query(Consent).filter_by(user_id=user.id, partner=item.partner, data_type=item.data_type).first()
        if row:
            row.allowed = item.allowed
    db.commit()
    return {"updated": len(req.items)}
