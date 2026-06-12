"""Train and evaluate the credit-risk default models.

Will use features from src/features.py to:

1. Train a logistic regression baseline (interpretable — report coefficients
   as the default drivers).
2. Train a gradient-boosting / random-forest challenger and compare.
3. Handle class imbalance (class weights or resampling — choice documented).
4. Evaluate with the metrics banks use: ROC-AUC, precision-recall curve,
   confusion matrix at a chosen threshold (framed as cost of a missed
   default vs. a rejected good borrower), and the KS statistic.

Run as a script:

    python src/train.py
"""

# TODO: implement after features.py — Weekend 2 of the project plan.

if __name__ == "__main__":
    raise SystemExit("Not implemented yet — see module docstring for the plan.")
