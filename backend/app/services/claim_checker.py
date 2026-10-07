"""Rule-based claim rejection predictor (swap with an XGBoost model later)."""


def check_claim(bill, req) -> dict:
    issues, suggestions, risk = [], [], 5
    total = bill.total or 0

    if not req.policy_active:
        issues.append("Policy is not active"); risk += 60
        suggestions.append("Renew or reinstate the policy before filing")
    if not req.policy_number.strip():
        issues.append("Policy number missing"); risk += 25
        suggestions.append("Add the policy number exactly as printed on the card")
    if bill.category == "hospital" or total > 10000:
        if not req.has_discharge_summary:
            issues.append("Discharge summary not attached"); risk += 25
            suggestions.append("Upload the discharge summary from the hospital")
        if total > 25000 and not req.pre_authorized:
            issues.append("No pre-authorization for a high-value claim"); risk += 20
            suggestions.append("Request cashless pre-authorization or attach the insurer's approval")
    if any(i.get("category") == "medicine" for i in bill.items or []) and not req.has_prescription:
        issues.append("Prescription missing for medicines"); risk += 20
        suggestions.append("Attach the doctor's prescription that matches the medicine list")
    if bill.flags:
        issues.append(f"{len(bill.flags)} item(s) flagged as overpriced"); risk += 15
        suggestions.append("Ask the provider to clarify or correct the flagged items")
    if not req.diagnosis.strip():
        issues.append("Diagnosis not stated"); risk += 10
        suggestions.append("Enter the diagnosis as written by the doctor")

    risk = min(risk, 100)
    level = "high" if risk >= 60 else "medium" if risk >= 30 else "low"
    return {"risk_score": risk, "risk_level": level, "issues": issues, "suggestions": suggestions}
