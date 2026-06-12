# Credit-Risk Default Prediction

Predicting consumer-loan default from borrower and loan attributes — built with **SQL**, **Python**, and **Tableau**.

> **TL;DR:** Designed a normalized SQL database of `<N>` loans, quantified default risk by grade/purpose/segment, and trained models reaching **`<0.__>` ROC-AUC** to predict default. [Live dashboard](<TABLEAU_LINK>)

---

## Business question

Lenders make money by pricing risk correctly. This project asks: **which borrowers and loan characteristics drive default, and can a model flag high-risk loans before they're funded?** The goal is a defensible, interpretable view of credit risk — the kind a bank's risk or analytics team would act on.

## Data

- **Source:** `<dataset name>` (`<link>`) — `<N>` consumer loans with outcome labels (fully paid vs. charged-off/default).
- **Key fields:** loan amount, interest rate, grade/sub-grade, purpose, term, borrower income, DTI, employment length, home ownership.
- Raw data is gitignored; see `data/README.md` for the download steps.

## Approach

1. **SQL** — designed a normalized schema, loaded the data, and answered risk questions with joins, aggregations, and window functions.
2. **Modeling** — engineered features, then trained an interpretable baseline and a stronger model, handling class imbalance.
3. **Communication** — published an interactive Tableau dashboard and summarized findings for a lending decision.

## Key findings

> _Fill in once your queries/models run — quantify everything._

- Highest-risk grade (`<G>`) defaulted at **`<__>%`** vs. **`<__>%`** overall.
- Top default drivers: **`<feature 1>`, `<feature 2>`, `<feature 3>`**.
- Best model: **`<model>`**, ROC-AUC **`<0.__>`**, KS **`<0.__>`**.

## Repo structure

```
credit-risk-analysis/
├── README.md
├── requirements.txt
├── data/
│   ├── raw/            # original download (gitignored)
│   └── loans.db        # SQLite database built from raw
├── sql/
│   ├── 01_schema.sql   # CREATE TABLE statements
│   ├── 02_load.sql     # load CSV into tables
│   └── 03_analysis.sql # analytical queries (the showcase)
├── notebooks/
│   ├── eda.ipynb       # exploration + charts
│   └── model.ipynb     # modeling + evaluation
├── src/
│   ├── features.py     # feature engineering
│   └── train.py        # train + evaluate
└── dashboard/          # Tableau file / screenshots
```

## Schema

```sql
CREATE TABLE borrowers (
    borrower_id     INTEGER PRIMARY KEY,
    annual_income   REAL,
    emp_length      INTEGER,
    home_ownership  TEXT,
    state           TEXT
);

CREATE TABLE loans (
    loan_id      INTEGER PRIMARY KEY,
    borrower_id  INTEGER REFERENCES borrowers(borrower_id),
    amount       REAL,
    grade        TEXT,
    sub_grade    TEXT,
    int_rate     REAL,
    purpose      TEXT,
    term         INTEGER,
    issue_date   DATE,
    status       TEXT  -- 'paid' | 'default'
);
```

## Example query

```sql
-- Default rate and average interest rate by grade:
-- does pricing line up with realized risk?
SELECT l.grade,
       COUNT(*)                                              AS n_loans,
       ROUND(AVG(l.int_rate), 2)                             AS avg_rate,
       ROUND(100.0 * SUM(CASE WHEN l.status = 'default'
             THEN 1 ELSE 0 END) / COUNT(*), 1)              AS default_rate_pct
FROM loans l
GROUP BY l.grade
ORDER BY l.grade;
```

## Modeling

| Model | ROC-AUC | KS | Notes |
|-------|---------|----|-------|
| Logistic Regression | `<0.__>` | `<0.__>` | Interpretable baseline; coefficients = default drivers |
| Gradient Boosting | `<0.__>` | `<0.__>` | Higher accuracy; compared against baseline |

- Class imbalance handled via `<class weights / resampling>`.
- Evaluated with ROC-AUC, precision-recall, confusion matrix (framed as cost of a missed default vs. a rejected good borrower), and the KS statistic.

## Dashboard

Interactive Tableau Public dashboard: **[View it here](<TABLEAU_LINK>)**

![Dashboard preview](dashboard/preview.png)

## Reproduce

```bash
git clone <repo-url>
cd credit-risk-analysis
pip install -r requirements.txt

# 1. Build the database
sqlite3 data/loans.db < sql/01_schema.sql
sqlite3 data/loans.db < sql/02_load.sql

# 2. Run the analysis queries
sqlite3 data/loans.db < sql/03_analysis.sql

# 3. Train and evaluate
python src/train.py
```

## Tech stack

Python · pandas · scikit-learn · SQL (SQLite) · Tableau · matplotlib/seaborn

## About

Built by **Hampton Abbott** — B.S. Sports Analytics, UNC Charlotte.
[Portfolio](https://hamptonabbott.com) · [GitHub](https://github.com/HPAuncc) · [LinkedIn](https://www.linkedin.com/in/hamptonabbott)

## License

MIT
