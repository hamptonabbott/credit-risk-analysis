"""Train and evaluate the credit-risk default models.

On a stratified 80/20 split of the 1.35M completed loans:

1. Logistic regression (class_weight='balanced') — interpretable baseline;
   scaled coefficients reported as the default drivers.
2. Gradient boosting (HistGradientBoostingClassifier) — the challenger.

Both run twice: with all features, then borrower-only (no grade / interest
rate), compared against Lending Club's own sub-grade ranking as a benchmark.

Class imbalance (~20% defaults) is handled with class weights — it keeps all
1.35M rows in play, unlike downsampling, and calibrates the 0.5 threshold.

Metrics: ROC-AUC, PR-AUC (average precision), KS statistic, and a confusion
matrix at the 0.5 threshold framed as caught defaults vs. falsely flagged
good borrowers.

Also writes the dashboard extracts dashboard/data/model_metrics.csv and
dashboard/data/top_default_drivers.csv from the evaluation results.

Run:  .venv/bin/python src/train.py
"""

import csv
import time
from pathlib import Path

import numpy as np
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (average_precision_score, confusion_matrix,
                             roc_auc_score, roc_curve)
from sklearn.model_selection import train_test_split
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler

from features import load_features

RANDOM_STATE = 42


def ks_statistic(y_true, y_score):
    """Kolmogorov-Smirnov: max separation between the cumulative score
    distributions of defaulters and non-defaulters (standard credit metric)."""
    fpr, tpr, _ = roc_curve(y_true, y_score)
    return float(np.max(tpr - fpr))


def evaluate(name, y_true, scores, threshold=0.5):
    """Print and return the metric row for one model."""
    row = {
        "model": name,
        "roc_auc": roc_auc_score(y_true, scores),
        "pr_auc": average_precision_score(y_true, scores),
        "ks": ks_statistic(y_true, scores),
    }
    print(f"\n{name}")
    print(f"  ROC-AUC {row['roc_auc']:.3f} | PR-AUC {row['pr_auc']:.3f} "
          f"| KS {row['ks']:.3f}")
    if threshold is not None:
        pred = (np.asarray(scores) >= threshold).astype(int)
        tn, fp, fn, tp = confusion_matrix(y_true, pred).ravel()
        row["precision"] = tp / (tp + fp)
        row["recall"] = tp / (tp + fn)
        print(f"  At threshold {threshold:.2f}: catches {tp:,}/{tp + fn:,} "
              f"defaults ({100 * tp / (tp + fn):.1f}%) while flagging "
              f"{fp:,} good loans ({100 * fp / (fp + tn):.1f}% of good) — "
              f"the cost trade-off: a missed default loses principal, a "
              f"flagged good borrower loses interest income.")
    return row


def top_drivers(logit_pipeline, columns, k=8):
    """Largest standardized coefficients = strongest default drivers."""
    coefs = logit_pipeline[-1].coef_[0]
    order = np.argsort(np.abs(coefs))[::-1][:k]
    return [(columns[i], coefs[i]) for i in order]


def main():
    rows = []
    for label, borrower_only in (("all features", False),
                                 ("borrower-only", True)):
        X, y, lender = load_features(borrower_only=borrower_only)
        X_tr, X_te, y_tr, y_te, _, lender_te = train_test_split(
            X, y, lender, test_size=0.2, stratify=y,
            random_state=RANDOM_STATE)
        print(f"\n=== Variant: {label} — {X.shape[1]} features, "
              f"train {len(X_tr):,} / test {len(X_te):,} ===")

        logit = make_pipeline(
            StandardScaler(),
            LogisticRegression(class_weight="balanced", max_iter=2000))
        t0 = time.time()
        logit.fit(X_tr, y_tr)
        print(f"[logistic fit {time.time() - t0:.0f}s]", end="")
        rows.append(evaluate(f"Logistic regression ({label})",
                             y_te, logit.predict_proba(X_te)[:, 1]))
        print("  Top drivers (standardized coefficients, + raises risk):")
        for name, coef in top_drivers(logit, list(X.columns)):
            print(f"    {coef:+.3f}  {name}")
        if not borrower_only:
            drivers = top_drivers(logit, list(X.columns), k=12)

        gb = HistGradientBoostingClassifier(class_weight="balanced",
                                            random_state=RANDOM_STATE)
        t0 = time.time()
        gb.fit(X_tr, y_tr)
        print(f"[gradient boosting fit {time.time() - t0:.0f}s]", end="")
        rows.append(evaluate(f"Gradient boosting ({label})",
                             y_te, gb.predict_proba(X_te)[:, 1]))

    # Benchmark: LC's own sub-grade as the risk score, same test rows
    # (same split: identical y order, stratify, and random_state).
    rows.append(evaluate("LC sub-grade benchmark", y_te, lender_te,
                         threshold=None))

    print("\n=== Summary ===")
    print(f"{'model':<40} {'ROC-AUC':>8} {'PR-AUC':>8} {'KS':>6}")
    for r in rows:
        print(f"{r['model']:<40} {r['roc_auc']:>8.3f} "
              f"{r['pr_auc']:>8.3f} {r['ks']:>6.3f}")

    # Dashboard extracts (precision/recall at the 0.5 threshold; blank for
    # the threshold-free sub-grade benchmark).
    out_dir = Path(__file__).resolve().parents[1] / "dashboard" / "data"
    out_dir.mkdir(parents=True, exist_ok=True)
    with open(out_dir / "model_metrics.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["model", "roc_auc", "pr_auc", "ks", "precision", "recall"])
        for r in rows:
            w.writerow([r["model"], f"{r['roc_auc']:.3f}",
                        f"{r['pr_auc']:.3f}", f"{r['ks']:.3f}",
                        f"{r['precision']:.3f}" if "precision" in r else "",
                        f"{r['recall']:.3f}" if "recall" in r else ""])
    with open(out_dir / "top_default_drivers.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["feature", "coefficient"])
        for name, coef in drivers:
            w.writerow([name, f"{coef:.3f}"])
    print(f"\nDashboard extracts written to {out_dir}")


if __name__ == "__main__":
    main()
