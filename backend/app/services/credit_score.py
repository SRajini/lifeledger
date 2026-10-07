"""Alternative credit score (300-900) from health-spending behaviour.

Uses ml/train_models.py output if present, else a transparent rule-based score.
"""
import os

MODEL_PATH = os.path.join(os.path.dirname(__file__), "..", "..", "data", "credit_model.joblib")


def features(bills, loans, pot) -> list:
    months = {b.bill_date.strftime("%Y-%m") for b in bills if b.category == "medicine"}
    avg_bill = sum(b.total for b in bills) / len(bills) if bills else 0
    repaid = sum(1 for l in loans if l.status == "closed")
    saved_ratio = (pot.saved / pot.target) if pot and pot.target else 0
    return [len(months), avg_bill, repaid, saved_ratio]


def score(bills, loans, pot) -> dict:
    f = features(bills, loans, pot)
    value = None
    if os.path.exists(MODEL_PATH):
        try:
            import joblib
            value = int(joblib.load(MODEL_PATH).predict([f])[0])
        except Exception:
            value = None
    if value is None:
        value = 550 + min(f[0], 6) * 20 + min(f[2], 3) * 30 + int(f[3] * 100)
        if f[1] > 20000:
            value -= 20
    value = max(300, min(900, value))
    band = "excellent" if value >= 750 else "good" if value >= 650 else "fair" if value >= 550 else "building"
    return {"score": value, "band": band,
            "factors": {"months_of_medicine_purchases": f[0], "loans_repaid": f[2], "savings_progress": round(f[3], 2)}}
