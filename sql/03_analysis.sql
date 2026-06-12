-- 03_analysis.sql — the analytical queries (the showcase).
-- Each query opens with the business question it answers.
-- Run: sqlite3 -header -column data/loans.db < sql/03_analysis.sql

-- 1. Does Lending Club's letter grade actually order risk?
--    Default rate by grade — the headline risk relationship.
SELECT grade,
       COUNT(*) AS n_loans,
       ROUND(100.0 * SUM(status = 'default') / COUNT(*), 1) AS default_rate_pct
FROM loans
GROUP BY grade
ORDER BY grade;

-- 2. Which loan purposes carry the most risk?
SELECT purpose,
       COUNT(*) AS n_loans,
       ROUND(100.0 * SUM(status = 'default') / COUNT(*), 1) AS default_rate_pct
FROM loans
GROUP BY purpose
HAVING COUNT(*) >= 1000
ORDER BY default_rate_pct DESC;

-- 3. Does borrower income protect against default?
--    Default rate by income band (segmentation with CASE + join).
SELECT CASE
           WHEN b.annual_income < 40000  THEN '1. under $40k'
           WHEN b.annual_income < 80000  THEN '2. $40k-$80k'
           WHEN b.annual_income < 120000 THEN '3. $80k-$120k'
           ELSE                               '4. $120k+'
       END AS income_band,
       COUNT(*) AS n_loans,
       ROUND(100.0 * SUM(l.status = 'default') / COUNT(*), 1) AS default_rate_pct
FROM loans l
JOIN borrowers b ON b.borrower_id = l.borrower_id
WHERE b.annual_income IS NOT NULL
GROUP BY income_band
ORDER BY income_band;

-- 4. How has the default rate evolved as the book grew?
--    Running cumulative default rate by issue-year cohort (window function).
WITH yearly AS (
    SELECT CAST(strftime('%Y', issue_date) AS INTEGER) AS issue_year,
           COUNT(*) AS n_loans,
           SUM(status = 'default') AS n_defaults
    FROM loans
    GROUP BY issue_year
)
SELECT issue_year,
       n_loans,
       ROUND(100.0 * n_defaults / n_loans, 1) AS year_default_rate_pct,
       ROUND(100.0 * SUM(n_defaults) OVER (ORDER BY issue_year)
                   / SUM(n_loans)    OVER (ORDER BY issue_year), 1)
           AS cumulative_default_rate_pct
FROM yearly
ORDER BY issue_year;

-- 5. Does pricing match risk? Average interest rate vs. realized default
--    rate per grade, and the spread a defaulted point of risk buys.
SELECT grade,
       ROUND(AVG(int_rate), 2) AS avg_rate_pct,
       ROUND(100.0 * SUM(status = 'default') / COUNT(*), 1) AS default_rate_pct,
       ROUND(AVG(int_rate) - 100.0 * SUM(status = 'default') / COUNT(*), 1)
           AS rate_minus_default_spread
FROM loans
GROUP BY grade
ORDER BY grade;

-- 6. Where do risk factors stack? Top-risk segments via a multi-table JOIN
--    (grade x home ownership), minimum 5,000 loans for stability.
SELECT l.grade,
       b.home_ownership,
       COUNT(*) AS n_loans,
       ROUND(100.0 * SUM(l.status = 'default') / COUNT(*), 1) AS default_rate_pct
FROM loans l
JOIN borrowers b ON b.borrower_id = l.borrower_id
WHERE b.home_ownership IN ('RENT', 'MORTGAGE', 'OWN')
GROUP BY l.grade, b.home_ownership
HAVING COUNT(*) >= 5000
ORDER BY default_rate_pct DESC
LIMIT 10;

-- 7. Does employment tenure predict repayment?
SELECT b.emp_length,
       COUNT(*) AS n_loans,
       ROUND(100.0 * SUM(l.status = 'default') / COUNT(*), 1) AS default_rate_pct
FROM loans l
JOIN borrowers b ON b.borrower_id = l.borrower_id
WHERE b.emp_length IS NOT NULL
GROUP BY b.emp_length
ORDER BY b.emp_length;

-- 8. Which states default most? (feeds the dashboard map; min 5,000 loans)
SELECT b.state,
       COUNT(*) AS n_loans,
       ROUND(100.0 * SUM(l.status = 'default') / COUNT(*), 1) AS default_rate_pct
FROM loans l
JOIN borrowers b ON b.borrower_id = l.borrower_id
GROUP BY b.state
HAVING COUNT(*) >= 5000
ORDER BY default_rate_pct DESC
LIMIT 10;

-- 9. Is borrowing beyond your means the real driver? Loan-to-income deciles
--    (NTILE window function) vs. default rate.
WITH lti AS (
    SELECT l.status,
           l.amount / b.annual_income AS loan_to_income,
           NTILE(10) OVER (ORDER BY l.amount / b.annual_income) AS lti_decile
    FROM loans l
    JOIN borrowers b ON b.borrower_id = l.borrower_id
    WHERE b.annual_income > 0
)
SELECT lti_decile,
       ROUND(MIN(loan_to_income), 3) AS lti_from,
       ROUND(MAX(loan_to_income), 3) AS lti_to,
       COUNT(*) AS n_loans,
       ROUND(100.0 * SUM(status = 'default') / COUNT(*), 1) AS default_rate_pct
FROM lti
GROUP BY lti_decile
ORDER BY lti_decile;

-- 10. How much extra risk does the 60-month term add within the same grade?
SELECT grade,
       ROUND(100.0 * SUM(CASE WHEN term = 36 AND status = 'default' THEN 1 END)
                   / SUM(term = 36), 1) AS default_36mo_pct,
       ROUND(100.0 * SUM(CASE WHEN term = 60 AND status = 'default' THEN 1 END)
                   / SUM(term = 60), 1) AS default_60mo_pct
FROM loans
GROUP BY grade
ORDER BY grade;
