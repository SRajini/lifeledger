from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db import get_db
from app.deps import current_user
from app.models import Bill, Loan, SavingsPot, User
from app.schemas import AcceptOfferRequest, ContributeRequest
from app.services import credit_score
from mock_apis.mock_data import bank_offers, insurer_topups, emi

router = APIRouter(prefix="/finance", tags=["finance"])


def _score(db, user):
    bills = db.query(Bill).filter_by(user_id=user.id).all()
    loans = db.query(Loan).filter_by(user_id=user.id).all()
    pot = db.query(SavingsPot).filter_by(user_id=user.id).first()
    return credit_score.score(bills, loans, pot), bills


@router.get("/credit-score")
def get_score(db: Session = Depends(get_db), user: User = Depends(current_user)):
    return _score(db, user)[0]


@router.get("/offers/{bill_id}")
def offers(bill_id: int, db: Session = Depends(get_db), user: User = Depends(current_user)):
    bill = db.query(Bill).filter_by(id=bill_id, user_id=user.id).first()
    if not bill:
        raise HTTPException(404, "Bill not found")
    sc, bills = _score(db, user)
    chronic = any(i.get("category") == "medicine" for b in bills for i in (b.items or []))
    return {"bill_total": bill.total, "credit_score": sc["score"],
            "loan_offers": bank_offers(bill.total, sc["score"]), "insurance_topups": insurer_topups(chronic)}


@router.post("/accept")
def accept(req: AcceptOfferRequest, db: Session = Depends(get_db), user: User = Depends(current_user)):
    rate = 0 if req.offer_type == "pay_later" else 15
    loan = Loan(user_id=user.id, bill_id=req.bill_id, offer_type=req.offer_type, amount=req.amount,
                tenure_months=req.tenure_months, emi=emi(req.amount, rate, req.tenure_months))
    db.add(loan); db.commit()
    return {"loan_id": loan.id, "emi": loan.emi, "status": "approved (demo)"}


@router.get("/savings")
def savings(db: Session = Depends(get_db), user: User = Depends(current_user)):
    p = db.query(SavingsPot).filter_by(user_id=user.id).first()
    return {"goal": p.goal, "target": p.target, "saved": p.saved, "monthly_autodebit": p.monthly_autodebit}


@router.post("/savings/contribute")
def contribute(req: ContributeRequest, db: Session = Depends(get_db), user: User = Depends(current_user)):
    p = db.query(SavingsPot).filter_by(user_id=user.id).first()
    p.saved += max(req.amount, 0)
    db.commit()
    return {"saved": p.saved, "target": p.target}
