"""Extract raw text from an uploaded bill/prescription.

Order of attempts:
1. Plain-text upload (handy for tests).
2. pytesseract + Pillow if installed and the Tesseract binary exists.
3. Bundled sample bill so the demo never breaks on stage.
"""
import io
import os

SAMPLE = os.path.join(os.path.dirname(__file__), "..", "..", "data", "sample_bill.txt")


def extract_text(data: bytes, filename: str = "") -> str:
    try:
        text = data.decode("utf-8")
        if text.strip() and sum(c.isprintable() or c in "\n\r\t" for c in text) / len(text) > 0.95:
            return text
    except UnicodeDecodeError:
        pass

    try:
        from PIL import Image
        import pytesseract

        text = pytesseract.image_to_string(Image.open(io.BytesIO(data)))
        if text.strip():
            return text
    except Exception:
        pass

    with open(SAMPLE, encoding="utf-8") as f:
        return f.read()
