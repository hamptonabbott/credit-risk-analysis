"""Feature engineering for the credit-risk default model.

Reads borrowers x loans from the SQLite database (data/loans.db) and builds
the model matrix:

- Base features: log income, DTI, FICO, loan amount, interest rate, grade,
  purpose, term, employment length, home ownership.
- Engineered: loan_to_income ratio — validated as a clean monotonic driver
  in sql/03_analysis.sql (query 9: 12.5% default in the lowest decile vs.
  30.3% in the highest).
- Encoding: one-hot for categoricals (drop_first to avoid collinearity in
  the logistic model); numeric gaps median-imputed.
- Target: status == 'default'.

Also returns Lending Club's own sub-grade as an ordinal score (A1=1 .. G5=35),
kept OUT of the model matrix — it is the "can we beat the lender?" benchmark.

borrower_only=True additionally drops the lender's pricing signals (grade,
interest rate) so the model sees only borrower/loan attributes.
"""

import sqlite3
from pathlib import Path

import numpy as np
import pandas as pd

DB_PATH = Path(__file__).resolve().parents[1] / "data" / "loans.db"

QUERY = """
SELECT l.status, l.amount, l.int_rate, l.grade, l.sub_grade, l.purpose,
       l.term, b.annual_income, b.emp_length, b.home_ownership, b.dti, b.fico
FROM loans l
JOIN borrowers b ON b.borrower_id = l.borrower_id
"""


def load_features(borrower_only: bool = False):
    """Return (X, y, lender_score), row-aligned and ready for modeling."""
    with sqlite3.connect(DB_PATH) as con:
        df = pd.read_sql(QUERY, con)

    y = (df.pop("status") == "default").astype(int)

    # LC's sub-grade as an ordinal risk score: A1=1 ... G5=35.
    lender_score = ((df["sub_grade"].str[0].map(ord) - ord("A")) * 5
                    + df["sub_grade"].str[1].astype(int))
    df = df.drop(columns=["sub_grade"])

    df["loan_to_income"] = df["amount"] / df["annual_income"]
    df["log_income"] = np.log1p(df["annual_income"])
    df = df.drop(columns=["annual_income"])

    categoricals = ["grade", "purpose", "home_ownership"]
    if borrower_only:
        df = df.drop(columns=["grade", "int_rate"])
        categoricals = ["purpose", "home_ownership"]

    X = pd.get_dummies(df, columns=categoricals, drop_first=True, dtype=float)
    X = X.replace([np.inf, -np.inf], np.nan)
    X = X.fillna(X.median(numeric_only=True))
    return X, y, lender_score


if __name__ == "__main__":
    X, y, lender = load_features()
    print(f"X: {X.shape[0]:,} rows x {X.shape[1]} features")
    print(f"default rate: {y.mean():.4f}")
    print("features:", ", ".join(X.columns))
