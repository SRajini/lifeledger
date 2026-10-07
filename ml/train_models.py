"""Train a demo credit model on synthetic data and save it for the backend.

Usage:  python ml/train_models.py
"""
import os
import numpy as np
import joblib
from sklearn.ensemble import GradientBoostingRegressor

rng = np.random.default_rng(42)
n = 2000
months = rng.integers(0, 12, n)
avg_bill = rng.gamma(2.0, 4000, n)
repaid = rng.integers(0, 5, n)
saved_ratio = rng.uniform(0, 1, n)
X = np.column_stack([months, avg_bill, repaid, saved_ratio])
y = (520 + months * 18 + repaid * 35 + saved_ratio * 110 - np.clip(avg_bill - 15000, 0, None) * 0.004
     + rng.normal(0, 15, n)).clip(300, 900)

model = GradientBoostingRegressor(n_estimators=150, max_depth=3).fit(X, y)
out = os.path.join(os.path.dirname(__file__), "..", "backend", "data", "credit_model.joblib")
joblib.dump(model, out)
print("saved", os.path.abspath(out), "R2 =", round(model.score(X, y), 3))
