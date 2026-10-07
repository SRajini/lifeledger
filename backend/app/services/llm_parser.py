"""Turn raw bill text into structured JSON.

Uses an LLM when ANTHROPIC_API_KEY is set, otherwise a regex parser.
Output shape:
{provider, bill_date (YYYY-MM-DD), category, total, items:[{name, qty, price, category}]}
"""
import json
import os
import re
from datetime import date, datetime

MEDICINE_WORDS = ("mg", "tablet", "tab", "syrup", "capsule", "insulin", "paracetamol",
                  "metformin", "amlodipine", "atorvastatin", "azithromycin", "cetirizine", "pantoprazole")
DIAG_WORDS = ("test", "scan", "x-ray", "xray", "mri", "ecg", "cbc", "hba1c", "lipid", "pathology")

PROMPT = """Extract this medical bill into JSON only, no prose, no markdown fences.
Schema: {"provider": str, "bill_date": "YYYY-MM-DD", "total": number,
"items": [{"name": str, "qty": int, "price": number (line total), "category": "medicine|diagnostic|hospital"}]}
Bill text:
"""


def _item_category(name: str) -> str:
    n = name.lower()
    if any(w in n for w in DIAG_WORDS):
        return "diagnostic"
    if any(w in n for w in MEDICINE_WORDS):
        return "medicine"
    return "hospital"


def _parse_date(text: str) -> str:
    m = re.search(r"(\d{1,2})[/-](\d{1,2})[/-](\d{4})", text)
    if m:
        d, mo, y = map(int, m.groups())
        try:
            return date(y, mo, d).isoformat()
        except ValueError:
            pass
    m = re.search(r"(\d{4})-(\d{2})-(\d{2})", text)
    if m:
        return m.group(0)
    return date.today().isoformat()


def _rule_based(text: str) -> dict:
    lines = [l.strip() for l in text.splitlines() if l.strip()]
    provider = lines[0] if lines else "Unknown"
    items, total = [], None
    for line in lines[1:]:
        if line.lower().startswith("date"):
            continue
        nums = re.findall(r"\d+(?:\.\d+)?", line)
        if not nums:
            continue
        price = float(nums[-1].replace(",", ""))
        if line.lower().startswith("total"):
            total = price
            continue
        name = re.split(r"\s+x\s*\d+|\s+\d+(?:\.\d+)?\s*$", line, maxsplit=1)[0]
        name = re.sub(r"\s+\d+\s*$", "", name).strip() or line
        qm = re.search(r"\bx\s*(\d+)", line, re.I)
        qty = int(qm.group(1)) if qm else (int(nums[-2]) if len(nums) >= 2 and "." not in nums[-2] else 1)
        items.append({"name": name, "qty": qty, "price": price, "category": _item_category(name)})
    if total is None:
        total = sum(i["price"] for i in items)
    return {"provider": provider, "bill_date": _parse_date(text), "total": total, "items": items}


def _llm(text: str):
    key = os.getenv("ANTHROPIC_API_KEY")
    if not key:
        return None
    try:
        import anthropic

        client = anthropic.Anthropic(api_key=key)
        msg = client.messages.create(
            model=os.getenv("LLM_MODEL", "claude-sonnet-5-5"),
            max_tokens=1500,
            messages=[{"role": "user", "content": PROMPT + text}],
        )
        raw = "".join(b.text for b in msg.content if getattr(b, "type", "") == "text")
        raw = re.sub(r"```json|```", "", raw).strip()
        return json.loads(raw)
    except Exception:
        return None


def parse_bill(text: str) -> dict:
    data = _llm(text) or _rule_based(text)
    cats = {i["category"] for i in data["items"]}
    data["category"] = "medicine" if cats == {"medicine"} else ("diagnostic" if cats == {"diagnostic"} else "hospital")
    return data
