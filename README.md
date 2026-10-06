# LifeLedger

Unified health-finance wallet for the Retail x Healthcare x BFSI hackathon.

## Run the backend
```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env            # optional: add ANTHROPIC_API_KEY for LLM bill parsing
uvicorn app.main:app --reload   # http://localhost:8000/docs
```
Optional: `python ../ml/train_models.py` to train the demo credit model.
Optional: `uvicorn mock_apis.server:app --port 8001` for the stand-alone partner mocks.

Or with Docker: `docker compose up --build`

## Run the app
```bash
cd mobile
flutter create .                # generates android/ios folders (keeps lib/ and pubspec.yaml)
flutter pub get
flutter run                     # Android emulator -> API at http://10.0.2.2:8000
# real phone:  flutter run --dart-define=API_URL=http://<your-laptop-ip>:8000
```
Android camera/gallery: nothing extra needed for image_picker on recent Flutter versions.
iOS: add NSCameraUsageDescription and NSPhotoLibraryUsageDescription to ios/Runner/Info.plist.

## Demo script (2 minutes)
1. Log in with any phone number, OTP `123456`.
2. Scan tab -> upload any image. Without Tesseract the bundled sample bill is used,
   so the overpriced blood test and gloves are flagged every time.
3. Home tab -> forecast, refills, reorder for points.
4. Claims tab -> leave fields empty to show a high-risk result, then toggle documents.
5. Pay tab -> accept a 0% pay-later offer.
6. Savings tab -> add money to the health pot.

## Where to improve first
- `claim_checker.py`: replace rules with a trained model.
- `overbilling.py`: grow `data/reference_prices.csv` with real price lists.
- `routers/consent.py`: enforce consent before partner endpoints return data.
- Replace the demo OTP in `routers/auth.py` with an SMS provider.
