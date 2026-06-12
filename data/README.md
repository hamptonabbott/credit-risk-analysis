# Data

## Getting the dataset (Lending Club loan data)

The raw data is **not** committed to git (too large). Download it yourself:

1. Create a free [Kaggle](https://www.kaggle.com) account if you don't have one.
2. Search Kaggle for **"Lending Club loan data"** — the commonly used dataset
   is `wordsforthewise/lending-club` (accepted + rejected loans, 2007–2018).
   Only the **accepted** loans file is needed (it has the outcome labels).
3. Download and unzip the accepted-loans CSV into `data/raw/`, e.g.:

   ```
   data/raw/accepted_2007_to_2018Q4.csv
   ```

4. Build the database from the repo root:

   ```bash
   sqlite3 data/loans.db < sql/01_schema.sql
   sqlite3 data/loans.db < sql/02_load.sql
   ```

`data/raw/` and `*.db` are gitignored — only this README travels with the repo.
