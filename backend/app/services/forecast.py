"""Simple expense forecast: recent average plus damped trend, with a safety buffer."""
from collections import defaultdict


def monthly_totals(bills):
    totals = defaultdict(float)
    for b in bills:
        totals[b.bill_date.strftime("%Y-%m")] += b.total or 0
    return dict(sorted(totals.items()))


def recurring_medicine(bills) -> float:
    per_month = defaultdict(float)
    for b in bills:
        med = sum(i["price"] for i in (b.items or []) if i.get("category") == "medicine")
        if med:
            per_month[b.bill_date.strftime("%Y-%m")] += med
    return round(sum(per_month.values()) / len(per_month), 2) if per_month else 0.0


def forecast_next_month(bills) -> dict:
    totals = monthly_totals(bills)
    values = list(totals.values())
    history = [{"month": m, "total": round(v, 2)} for m, v in totals.items()]
    if not values:
        return {"history": [], "predicted_next_month": 0, "recommended_saving": 0, "recurring_medicine": 0}
    base = sum(values[-3:]) / len(values[-3:])
    trend = (values[-1] - values[0]) / (len(values) - 1) if len(values) > 1 else 0
    predicted = max(base + 0.5 * trend, 0)
    return {
        "history": history,
        "predicted_next_month": round(predicted, 2),
        "recommended_saving": round(predicted * 1.15, 2),  # 15% buffer for surprises
        "recurring_medicine": recurring_medicine(bills),
    }
