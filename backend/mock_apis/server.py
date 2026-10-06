"""Optional stand-alone mock partner server: uvicorn mock_apis.server:app --port 8001"""
from fastapi import FastAPI
from mock_apis.mock_data import bank_offers, insurer_topups, PHARMACY_CATALOG

app = FastAPI(title="LifeLedger mock partners")


@app.get("/bank/offers")
def offers(amount: float, score: int = 600):
    return bank_offers(amount, score)


@app.get("/insurer/topups")
def topups(chronic: bool = False):
    return insurer_topups(chronic)


@app.get("/pharmacy/catalog")
def catalog():
    return PHARMACY_CATALOG
