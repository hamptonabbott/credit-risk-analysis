-- 01_schema.sql — normalized schema for the Lending Club loan database.
--
-- The raw download is one flat 151-column CSV (one row per loan, borrower
-- fields repeated inline). We split it into a small normalized schema so the
-- analysis queries use real joins. The dataset is anonymized with no reusable
-- borrower key (member_id is empty), so borrowers is derived 1:1 from loans —
-- the split demonstrates schema design, not deduplication.
--
-- Scope: completed loans only (Fully Paid -> 'paid', Charged Off -> 'default').
-- Loans still in flight (Current / Late / Grace) have no final outcome and are
-- excluded at load time.

DROP TABLE IF EXISTS loans;
DROP TABLE IF EXISTS borrowers;

CREATE TABLE borrowers (
    borrower_id     INTEGER PRIMARY KEY,
    annual_income   REAL,
    emp_length      INTEGER,   -- years; 0 = under 1 year, 10 = 10+ years
    home_ownership  TEXT,      -- RENT | MORTGAGE | OWN | ...
    state           TEXT,      -- two-letter US state
    dti             REAL,      -- debt-to-income ratio (%)
    fico            REAL       -- midpoint of FICO range at issue
);

CREATE TABLE loans (
    loan_id      INTEGER PRIMARY KEY,
    borrower_id  INTEGER NOT NULL REFERENCES borrowers(borrower_id),
    amount       REAL,
    grade        TEXT,         -- A (least risky) .. G (most risky)
    sub_grade    TEXT,         -- A1 .. G5
    int_rate     REAL,         -- annual interest rate (%)
    purpose      TEXT,
    term         INTEGER,      -- months: 36 | 60
    issue_date   DATE,
    status       TEXT NOT NULL CHECK (status IN ('paid', 'default'))
);

CREATE INDEX idx_loans_borrower ON loans(borrower_id);
CREATE INDEX idx_loans_grade    ON loans(grade);
CREATE INDEX idx_loans_status   ON loans(status);
CREATE INDEX idx_loans_issued   ON loans(issue_date);
