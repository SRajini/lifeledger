from datetime import timedelta
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db import get_db
from app.deps import current_user
from app.models import Bill, Order, User
from app.schemas import OrderRequest
from mock_apis.mock_data import PHARMACY_CATALOG

router = APIRouter(prefix="/retail", tags=["retail"])
REFILL_DAYS = 30


@router.get("/refills")
def refills(db: Session = Depends(get_db), user: User = Depends(current_user)):
    last_seen = {}
    for b in db.query(Bill).filter_by(user_id=user.id).order_by(Bill.bill_date).all():
        for it in b.items or []:
            if it.get("category") == "medicine":
                last_seen[it["name"]] = b.bill_date
    out = []
    for name, d in last_seen.items():
        key = next((k for k in PHARMACY_CATALOG if k in name.lower()), None)
        out.append({"medicine": name, "next_refill_date": (d + timedelta(days=REFILL_DAYS)).isoformat(),
                    "generic_alternative": PHARMACY_CATALOG[key]["generic_alt"] if key else None})
    return sorted(out, key=lambda x: x["next_refill_date"])


@router.post("/order")
def order(req: OrderRequest, db: Session = Depends(get_db), user: User = Depends(current_user)):
    key = next((k for k in PHARMACY_CATALOG if k in req.medicine.lower()), None)
    points = (PHARMACY_CATALOG[key]["points_per_unit"] if key else 1) * req.qty
    o = Order(user_id=user.id, medicine=req.medicine, qty=req.qty, points_earned=points)
    db.add(o); db.commit()
    return {"order_id": o.id, "points_earned": points, "status": "placed"}
