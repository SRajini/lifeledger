from datetime import datetime, date
from sqlalchemy import Column, Integer, String, Float, Date, DateTime, Boolean, ForeignKey, JSON
from app.db import Base


class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True)
    phone = Column(String, unique=True, index=True)
    name = Column(String, default="")
    created_at = Column(DateTime, default=datetime.utcnow)


class Bill(Base):
    __tablename__ = "bills"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    provider = Column(String, default="Unknown")
    bill_date = Column(Date, default=date.today)
    category = Column(String, default="general")  # medicine | hospital | diagnostic | general
    total = Column(Float, default=0.0)
    items = Column(JSON, default=list)   # [{name, qty, price, category}]
    flags = Column(JSON, default=list)   # overbilling flags
    raw_text = Column(String, default="")
    created_at = Column(DateTime, default=datetime.utcnow)


class Claim(Base):
    __tablename__ = "claims"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    bill_id = Column(Integer, ForeignKey("bills.id"))
    risk_score = Column(Integer, default=0)
    result = Column(JSON, default=dict)
    created_at = Column(DateTime, default=datetime.utcnow)


class Consent(Base):
    __tablename__ = "consents"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    partner = Column(String)       # bank | insurer | pharmacy
    data_type = Column(String)     # bills | purchases | credit_score
    allowed = Column(Boolean, default=False)


class Loan(Base):
    __tablename__ = "loans"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    bill_id = Column(Integer, ForeignKey("bills.id"))
    offer_type = Column(String)
    amount = Column(Float)
    tenure_months = Column(Integer)
    emi = Column(Float)
    status = Column(String, default="active")
    created_at = Column(DateTime, default=datetime.utcnow)


class SavingsPot(Base):
    __tablename__ = "savings_pots"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)
    goal = Column(String, default="Health emergency fund")
    target = Column(Float, default=25000.0)
    saved = Column(Float, default=0.0)
    monthly_autodebit = Column(Float, default=1000.0)


class Order(Base):
    __tablename__ = "orders"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    medicine = Column(String)
    qty = Column(Integer, default=1)
    points_earned = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)
