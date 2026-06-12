# Tableau Public — step-by-step build guide

Builds the credit-risk dashboard from the CSVs in `dashboard/data/`, assuming
zero prior Tableau experience. Expect 60–90 minutes end to end.

## 0. Setup (once)

1. Go to [public.tableau.com](https://public.tableau.com) → **Sign Up** for a
   free Tableau Public account (this account also hosts your published link).
2. Download and install **Tableau Public** (the free desktop app) from the
   same site, and sign in inside the app.

> Tableau Public has no local save — saving publishes to your online profile.
> Build everything, then save once at the end.

## 1. Connect the data

1. Open Tableau Public → on the start page under **Connect → To a File**,
   click **Text file** and pick `dashboard/data/default_rate_by_grade.csv`.
2. You land on the Data Source page; the CSV's columns appear. Click
   **Sheet 1** (bottom-left) to start building.
3. For each later view that uses a *different* CSV: **Data → New Data
   Source → Text file** and pick that CSV. Each CSV is its own small data
   source — no joins needed, they're pre-aggregated by the SQL in
   `sql/04_dashboard_extracts.sql`.

> **Convention used below:** drag fields from the left Data pane onto the
> **Columns** / **Rows** shelves or the **Marks** card (Color, Label, Size,
> Tooltip). Tableau will wrap measures as `SUM(...)` — with one row per
> category in these CSVs, SUM of one value is just the value, so that's fine.

## 2. The views (one worksheet each)

Rename each sheet (double-click its tab) to the name in **bold**.

### Sheet 1 — **Default Rate by Grade** (the headline)

Data: `default_rate_by_grade.csv`

1. Drag `Grade` → **Columns**.
2. Drag `Default Rate Pct` → **Rows**. You get bars going A → G.
3. Drag `Default Rate Pct` → **Color** on the Marks card; click **Color →
   Edit Colors → Red** palette so risk reads hot.
4. Drag `Default Rate Pct` → **Label** to print the % on each bar.
5. Bonus (pricing-vs-risk view): drag `Avg Int Rate` → **Rows** next to the
   first pill, right-click the second axis → **Dual Axis**, then right-click
   it again → **Synchronize Axis**. On the Marks card, set the `Avg Int Rate`
   marks to **Line**. Now the line shows the rate charged, the bars the loss
   realized — the grade-G gap (27.7% rate vs 49.9% default) is the story.
6. Title (double-click the title area): *"Default risk is steeply graded —
   and pricing doesn't keep pace"*.

### Sheet 2 — **Risk by Purpose**

Data: `default_rate_by_purpose.csv`

1. Drag `Default Rate Pct` → **Columns**, `Purpose` → **Rows** (horizontal
   bars).
2. Sort descending: click the sort-descending icon in the toolbar.
3. Drag `Default Rate Pct` → **Color** (same red palette);
   drag `N Loans` → **Tooltip** so hover shows volume.
4. Title: *"Small-business loans default most"*.

### Sheet 3 — **Risk by Income Band**

Data: `default_rate_by_income_band.csv`

1. `Income Band` → **Columns**, `Default Rate Pct` → **Rows**.
2. The bands are prefixed `1.`–`4.` so they sort correctly on their own.
3. `Default Rate Pct` → **Label**. Title: *"Income protects: 23.8% under
   $40k → 15.6% at $120k+"*.

### Sheet 4 — **Default Rate by State** (map)

Data: `default_rate_by_state.csv`

1. In the Data pane, right-click `State` → **Geographic Role → State/Province**.
2. Double-click `State` — Tableau draws the US map automatically.
3. Drag `Default Rate Pct` → **Color**; set the marks type to **Map**
   (filled states) if it isn't already. Red palette again.
4. `N Loans` → **Tooltip**. Title: *"Where defaults cluster (states with
   ≥5,000 loans)"*.

### Sheet 5 — **Segment Explorer** (grade × home ownership heatmap)

Data: `segment_grade_home_ownership.csv`

1. `Home Ownership` → **Columns**, `Grade` → **Rows**.
2. Set the mark type dropdown (Marks card) to **Square**.
3. `Default Rate Pct` → **Color**, `Default Rate Pct` → **Label**.
4. Result: a highlight table where F×RENT (48.9%) burns red and A×MORTGAGE
   (5.2%) stays cool — a 9× risk spread across segments.
5. Title: *"Risk stacks: renters out-default homeowners in every grade"*.

### Sheet 6 — **Model Performance**

Data: `model_metrics.csv`

1. `Model` → **Rows**.
2. Double-click in turn: `Roc Auc`, `Pr Auc`, `Ks`, `Precision`, `Recall` —
   Tableau builds a text table (they land on the **Measure Values** card).
3. Optional polish: drag `Roc Auc` → **Color** to shade the winning row.
4. Title: *"Models vs. the lender's own grade (test set: 269k loans)"*.

### Sheet 7 — **Default Drivers**

Data: `top_default_drivers.csv`

1. `Coefficient` → **Columns**, `Feature` → **Rows**, sorted descending.
2. `Coefficient` → **Color** → **Edit Colors → Red-Green Diverging**,
   centered at 0 (check "Use Full Color Range"), reversed so positive =
   red (raises risk), negative = green (protective).
3. Title: *"What drives default — standardized logistic coefficients"*.

## 3. Assemble the dashboard

1. Click the **New Dashboard** icon (bottom bar, grid-with-plus).
2. **Size** (left panel): set to **Automatic** (resizes to the viewer's
   browser — best for a portfolio link).
3. Drag sheets from the left panel onto the canvas. A layout that reads well:
   - **Top-left (hero, ~half width):** Default Rate by Grade.
   - **Top-right:** Model Performance stacked above Default Drivers.
   - **Bottom row, three tiles:** Risk by Purpose · Segment Explorer · State map.
   - Income Band fits as a fourth small tile or lives in the hero's tooltip
     story — don't overcrowd; 5–6 views max.
4. Add a title: drag a **Text** object to the very top — *"Credit-Risk
   Default Prediction — 1.35M Lending Club loans"* with a one-line subtitle
   linking the GitHub repo.
5. Interactivity: **Dashboard → Actions → Add Action → Highlight**, source =
   Default Rate by Grade, target = Segment Explorer. Clicking a grade bar now
   highlights that grade's row in the heatmap.
6. Eyeball every tile's fit (the dropdown on each tile → **Fit → Entire
   View** usually looks best).

## 4. Publish and get the link

1. **File → Save to Tableau Public As…** → name it
   `credit-risk-default-prediction` → it uploads and opens in your browser.
2. On the published page: **Edit Details** → write the one-paragraph
   description (reuse the README TL;DR), and under **Settings** make sure
   **"Show workbook sheets as tabs"** is off (single dashboard view).
3. The browser URL — `https://public.tableau.com/app/profile/<you>/viz/credit-risk-default-prediction/...`
   — is your share link. The **Share** button gives the same canonical URL.
4. Paste that URL into both `<TABLEAU_LINK>` placeholders in `README.md`
   (TL;DR and Dashboard sections) and into the portfolio card.
5. Take a full-dashboard screenshot, save it as `dashboard/preview.png`
   (the README already references that exact path), commit, push.

## Numbers to sanity-check after building

If these don't match, a field landed on the wrong shelf:

- Grade A default rate **6.0%**, grade G **49.9%** (overall 20.0%).
- Small business purpose **29.7%**.
- F × RENT segment **48.9%**; A × MORTGAGE **5.2%**.
- Best model row: gradient boosting (all features) **0.716 AUC / 0.314 KS**.
