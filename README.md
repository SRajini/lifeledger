# LifeLedger

Unified health-finance wallet (Retail x Healthcare x BFSI hackathon).

## 1. Run locally (Windows)
Backend (terminal 1, from `backend`):
    python -m venv .venv
    .venv\Scripts\activate
    pip install -r requirements.txt
    copy .env.example .env
    uvicorn app.main:app --reload
API docs: http://localhost:8000/docs

App (terminal 2, from `mobile`):
    flutter create . --platforms web
    flutter pub get
    flutter run -d chrome --dart-define=API_URL=http://localhost:8000
Login with any phone number, OTP 123456.

Keep the project OUTSIDE OneDrive (e.g. C:\dev\lifeledger) or Flutter's build folder may be locked.

## 2. Deploy the backend (Render)
1. Push this repo to GitHub (the .gitignore already excludes .venv, build and .env).
2. Render > New > Blueprint > pick the repo. render.yaml sets everything up.
3. Optional: add ANTHROPIC_API_KEY in the Render dashboard (leave blank to skip).
4. Copy your URL, e.g. https://lifeledger-api.onrender.com

## 3. Deploy the app (Vercel)
From `mobile`:
    flutter build web --release --dart-define=API_URL=https://YOUR-API.onrender.com
    cd build\web
    npx vercel --prod
Accept the defaults (no framework, current folder).

Notes: free Render sleeps when idle, so open the API URL a minute before your demo.
Camera is unavailable in desktop browsers; use Upload. Without Tesseract every upload
uses the bundled sample bill, which flags the overpriced blood test and gloves.
