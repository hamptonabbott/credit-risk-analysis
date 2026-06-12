-- 04_dashboard_extracts.sql — small CSV extracts for the Tableau dashboard.
-- Each extract is a query from 03_analysis.sql shaped for one dashboard view.
-- Run from the repo root:  sqlite3 data/loans.db < sql/04_dashboard_extracts.sql
-- (model_metrics.csv and top_default_drivers.csv come from src/train.py.)

.headers on
.mode csv

-- Headline view: default rate + pricing by grade (analysis queries 1 & 5).
.once dashboard/data/default_rate_by_grade.csv
SELECT grade,
       COUNT(*) AS n_loans,
       ROUND(AVG(int_rate), 2) AS avg_int_rate,
       ROUND(100.0 * SUM(status = 'default') / COUNT(*), 1) AS default_rate_pct
FROM loans
GROUP BY grade
ORDER BY grade;

-- Risk by purpose (analysis query 2).
.once dashboard/data/default_rate_by_purpose.csv
SELECT purpose,
       COUNT(*) AS n_loans,
       ROUND(100.0 * SUM(status = 'default') / COUNT(*), 1) AS default_rate_pct
FROM loans
GROUP BY purpose
HAVING COUNT(*) >= 1000
ORDER BY default_rate_pct DESC;

-- Risk by income band (analysis query 3).
.once dashboard/data/default_rate_by_income_band.csv
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

-- Map view: risk by state, all states with a stable base (analysis query 8,
-- without the LIMIT so the map has full coverage).
.once dashboard/data/default_rate_by_state.csv
SELECT b.state,
       COUNT(*) AS n_loans,
       ROUND(100.0 * SUM(l.status = 'default') / COUNT(*), 1) AS default_rate_pct
FROM loans l
JOIN borrowers b ON b.borrower_id = l.borrower_id
GROUP BY b.state
HAVING COUNT(*) >= 5000
ORDER BY b.state;

-- Segment explorer: grade x home ownership heatmap (analysis query 6,
-- without the LIMIT).
.once dashboard/data/segment_grade_home_ownership.csv
SELECT l.grade,
       b.home_ownership,
       COUNT(*) AS n_loans,
       ROUND(100.0 * SUM(l.status = 'default') / COUNT(*), 1) AS default_rate_pct
FROM loans l
JOIN borrowers b ON b.borrower_id = l.borrower_id
WHERE b.home_ownership IN ('RENT', 'MORTGAGE', 'OWN')
GROUP BY l.grade, b.home_ownership
HAVING COUNT(*) >= 5000
ORDER BY l.grade, b.home_ownership;

-- Cohort trend: issue-year volume and default rate (analysis query 4).
.once dashboard/data/default_rate_by_cohort.csv
SELECT CAST(strftime('%Y', issue_date) AS INTEGER) AS issue_year,
       COUNT(*) AS n_loans,
       ROUND(100.0 * SUM(status = 'default') / COUNT(*), 1) AS default_rate_pct
FROM loans
GROUP BY issue_year
ORDER BY issue_year;
