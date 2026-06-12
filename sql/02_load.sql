-- 02_load.sql — load the raw Lending Club CSV into the normalized tables.
--
-- Run from the repo root (paths are relative):
--   sqlite3 data/loans.db < sql/01_schema.sql
--   sqlite3 data/loans.db < sql/02_load.sql
--
-- Pipeline: .import the raw CSV into a staging table (SQLite creates it from
-- the header row, all TEXT), clean and normalize in SQL, INSERT...SELECT into
-- borrowers and loans, then drop staging. The raw file is ~1.6 GB / 2.26M
-- rows, so the import takes a few minutes.

-- Speed up the bulk load (safe here: the db is rebuilt from raw if it dies).
PRAGMA journal_mode = OFF;
PRAGMA synchronous = OFF;

.mode csv
.import data/raw/accepted_2007_to_2018Q4.csv staging

-- Borrowers: one per loan (dataset is anonymized; see 01_schema.sql).
-- Cleaning: emp_length '10+ years'/'< 1 year'/'n/a' -> 10/0/NULL,
-- FICO = midpoint of the reported range.
INSERT INTO borrowers (borrower_id, annual_income, emp_length,
                       home_ownership, state, dti, fico)
SELECT CAST(id AS INTEGER),
       NULLIF(CAST(annual_inc AS REAL), 0),
       CASE
           WHEN emp_length = '10+ years' THEN 10
           WHEN emp_length = '< 1 year'  THEN 0
           WHEN emp_length IS NULL OR emp_length IN ('', 'n/a') THEN NULL
           ELSE CAST(substr(emp_length, 1, 2) AS INTEGER)
       END,
       home_ownership,
       addr_state,
       CAST(dti AS REAL),
       (CAST(fico_range_low AS REAL) + CAST(fico_range_high AS REAL)) / 2.0
FROM staging
WHERE id GLOB '[0-9]*'                          -- skip footer/junk rows
  AND loan_status IN ('Fully Paid', 'Charged Off');

-- Loans: completed outcomes only. Cleaning: term ' 36 months' -> 36,
-- int_rate to REAL, issue_d 'Dec-2015' -> '2015-12-01'.
INSERT INTO loans (loan_id, borrower_id, amount, grade, sub_grade,
                   int_rate, purpose, term, issue_date, status)
SELECT CAST(id AS INTEGER),
       CAST(id AS INTEGER),
       CAST(loan_amnt AS REAL),
       grade,
       sub_grade,
       CAST(REPLACE(TRIM(int_rate), '%', '') AS REAL),
       purpose,
       CAST(TRIM(REPLACE(term, 'months', '')) AS INTEGER),
       substr(issue_d, -4) || '-' ||
       CASE substr(issue_d, 1, 3)
           WHEN 'Jan' THEN '01' WHEN 'Feb' THEN '02' WHEN 'Mar' THEN '03'
           WHEN 'Apr' THEN '04' WHEN 'May' THEN '05' WHEN 'Jun' THEN '06'
           WHEN 'Jul' THEN '07' WHEN 'Aug' THEN '08' WHEN 'Sep' THEN '09'
           WHEN 'Oct' THEN '10' WHEN 'Nov' THEN '11' WHEN 'Dec' THEN '12'
       END || '-01',
       CASE loan_status WHEN 'Fully Paid' THEN 'paid' ELSE 'default' END
FROM staging
WHERE id GLOB '[0-9]*'
  AND loan_status IN ('Fully Paid', 'Charged Off');

DROP TABLE staging;
VACUUM;

-- Sanity check: row counts and overall default rate.
SELECT (SELECT COUNT(*) FROM borrowers) AS n_borrowers,
       (SELECT COUNT(*) FROM loans)     AS n_loans,
       (SELECT ROUND(100.0 * SUM(status = 'default') / COUNT(*), 2)
          FROM loans)                   AS default_rate_pct;
