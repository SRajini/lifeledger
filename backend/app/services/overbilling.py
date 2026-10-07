"""Flag bill items priced above the reference range (unit price)."""
import csv
import os
from difflib import get_close_matches

REF_PATH = os.path.join(os.path.dirname(__file__), "..", "..", "data", "reference_prices.csv")
TOLERANCE = 1.25  # allow 25% above the max reference price


def _load():
    with open(REF_PATH, encoding="utf-8") as f:
        return {r["item"]: r for r in csv.DictReader(f)}


def check_items(items: list) -> list:
    ref = _load()
    keys = list(ref.keys())
    flags = []
    for it in items:
        name = it["name"].lower()
        match = next((k for k in keys if k in name), None) or (
            (get_close_matches(name.split()[0], keys, n=1, cutoff=0.8) or [None])[0]
        )
        if not match:
            continue
        qty = max(int(it.get("qty") or 1), 1)
        unit = float(it["price"]) / qty
        r = ref[match]
        max_p = float(r["max_price"])
        if unit > max_p * TOLERANCE:
            flags.append({
                "item": it["name"],
                "unit_price": round(unit, 2),
                "expected_max": max_p,
                "overcharge_pct": round((unit / max_p - 1) * 100),
                "message": f"{it['name']} looks overpriced: ~{round(unit)} per unit vs usual max {round(max_p)}",
            })
    return flags
