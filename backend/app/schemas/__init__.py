from typing import List
from pydantic import BaseModel


class OtpRequest(BaseModel):
    phone: str


class OtpVerify(BaseModel):
    phone: str
    otp: str


class ClaimCheckRequest(BaseModel):
    bill_id: int
    policy_number: str = ""
    policy_active: bool = True
    pre_authorized: bool = False
    has_discharge_summary: bool = False
    has_prescription: bool = False
    diagnosis: str = ""


class OrderRequest(BaseModel):
    medicine: str
    qty: int = 1


class AcceptOfferRequest(BaseModel):
    bill_id: int
    offer_type: str
    amount: float
    tenure_months: int


class ContributeRequest(BaseModel):
    amount: float


class ConsentItem(BaseModel):
    partner: str
    data_type: str
    allowed: bool


class ConsentUpdate(BaseModel):
    items: List[ConsentItem]
