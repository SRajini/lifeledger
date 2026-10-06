"""Fake bank / insurer / pharmacy data so the demo works offline."""


def emi(amount: float, annual_rate: float, months: int) -> float:
    if annual_rate == 0:
        return round(amount / months, 2)
    r = annual_rate / 12 / 100
    return round(amount * r * (1 + r) ** months / ((1 + r) ** months - 1), 2)


def bank_offers(amount: float, credit_score: int) -> list:
    offers = []
    if amount <= 25000 and credit_score >= 550:
        offers.append({"offer_type": "pay_later", "title": "Pay later, 0% for 3 months",
                       "amount": amount, "tenure_months": 3, "rate": 0, "emi": emi(amount, 0, 3)})
    rate = 12 if credit_score >= 700 else 15 if credit_score >= 600 else 18
    limit = 50000 if credit_score >= 700 else 25000 if credit_score >= 600 else 10000
    amt = min(amount, limit)
    for tenure in (6, 12):
        offers.append({"offer_type": "micro_loan", "title": f"Health micro-loan, {tenure} months",
                       "amount": amt, "tenure_months": tenure, "rate": rate, "emi": emi(amt, rate, tenure)})
    return offers


def insurer_topups(has_chronic: bool) -> list:
    base = [{"name": "Hospital cash cover", "premium_per_month": 99, "cover": 50000}]
    if has_chronic:
        base.append({"name": "Chronic care top-up", "premium_per_month": 249, "cover": 200000})
    return base


PHARMACY_CATALOG = {
    "metformin": {"price": 3.0, "generic_alt": "Metformin (generic)", "points_per_unit": 1},
    "paracetamol": {"price": 2.0, "generic_alt": "Paracetamol (generic)", "points_per_unit": 1},
    "amlodipine": {"price": 4.0, "generic_alt": "Amlodipine (generic)", "points_per_unit": 1},
    "atorvastatin": {"price": 9.0, "generic_alt": "Atorvastatin (generic)", "points_per_unit": 2},
}
