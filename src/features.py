"""Feature engineering for the credit-risk default model.

Will read from the SQLite database (data/loans.db), join borrowers x loans,
and build the model matrix:

- Base features: annual income, DTI, loan amount, interest rate, grade,
  purpose, term, employment length, home ownership.
- Engineered features: loan-to-income ratio, income bands, and any others
  that EDA justifies.
- Encoding: one-hot for categoricals, with the target defined as
  status == 'default'.

Exposes a single entry point used by train.py:

    load_features() -> (X: pd.DataFrame, y: pd.Series)
"""

# TODO: implement after the SQL phase (schema + load) is complete.
