# NHS Trust Financial Analytics — Comprehensive Project Documentation

> A complete guide for anyone unfamiliar with this project: the business context, the data,
> the technology, the analytical findings, and how everything fits together.

---

## Table of Contents

1. [What is this project?](#1-what-is-this-project)
2. [The NHS — Background and Business Context](#2-the-nhs--background-and-business-context)
3. [The Financial Crisis in NHS Trusts](#3-the-financial-crisis-in-nhs-trusts)
4. [The Data Source — NHS TAC Publications](#4-the-data-source--nhs-tac-publications)
5. [The Data Model — How the Data is Structured](#5-the-data-model--how-the-data-is-structured)
6. [The Database Architecture](#6-the-database-architecture)
7. [The Data Pipeline](#7-the-data-pipeline)
8. [The Analytics Layer — SQL Views](#8-the-analytics-layer--sql-views)
9. [Key Performance Indicators (KPIs)](#9-key-performance-indicators-kpis)
10. [Key Findings from the Data](#10-key-findings-from-the-data)
11. [The Power BI Dashboard](#11-the-power-bi-dashboard)
12. [Project File Structure](#12-project-file-structure)
13. [How to Reproduce This Project](#13-how-to-reproduce-this-project)
14. [NHS Glossary](#14-nhs-glossary)

---

## 1. What is this project?

This is a **data engineering and financial analytics portfolio project** that answers a real-world question:

> *How is the financial health of NHS Trusts in England changing over time, and which parts of the health system are under the most pressure?*

To answer that question, this project:

1. Downloads **real, public NHS financial data** from NHS England's official publications
2. Builds a **MySQL data warehouse** to store and organise the data
3. Writes a **Python pipeline** to automatically load 6 large Excel files (~170MB of data) into the database
4. Creates **SQL analytical views** to compute financial metrics and KPIs
5. Exports **Power BI-ready CSV files** for dashboard visualisation

**The result:** A fully automated analytics pipeline covering **206 NHS organisations** across **3 financial years (2021/22 to 2023/24)**, with 2.18 million fact rows, surfacing a clear story about the deterioration of NHS financial health.

---

## 2. The NHS — Background and Business Context

### What is the NHS?

The **National Health Service (NHS)** is England's publicly funded healthcare system, established in 1948. It provides most healthcare free at the point of use, funded through general taxation. It is one of the largest employers in the world, with approximately **1.5 million staff**.

### What is an NHS Trust?

NHS healthcare is delivered by organisations called **Trusts**. Each Trust is a legal entity responsible for running hospitals, ambulance services, mental health services, or community health services within a defined geography or specialty.

There are two main types:

| Type | What they do | How governed |
|------|-------------|-------------|
| **NHS Trust** | Provide healthcare; not yet achieved Foundation status | Directly overseen by NHS England |
| **NHS Foundation Trust (FT)** | Provide healthcare; earned greater operational autonomy | Overseen by NHS England + NHS Improvement; have members and governors |

Foundation Trust status is a mark of financial and organisational maturity. Most large hospital groups are Foundation Trusts.

### What sectors do Trusts operate in?

| Sector | Description | Count (2023/24) |
|--------|-------------|----------------|
| **Acute** | General hospitals (A&E, surgery, maternity, cancer) | 118 |
| **Mental Health** | Inpatient and community mental health | 45 |
| **Specialist** | Nationally specialised services (e.g. Great Ormond Street) | 15 |
| **Community** | District nursing, physiotherapy, health visiting | 18 |
| **Ambulance** | Emergency and non-emergency ambulance services | 10 |

### How are NHS Trusts funded?

- **Patient care income** (~82–85% of revenue): NHS England and Integrated Care Boards (ICBs) pay Trusts for delivering clinical activity. The main payment mechanism is **Aligned Payment and Incentive (API)** contracts — a block payment for expected activity.
- **Other operating income** (~15–18%): Research grants, education and training, non-NHS commercial services (e.g. car parking), and charitable funds.

### What do NHS Trusts spend money on?

- **Pay (~65–70% of expenditure)**: Salaries, national insurance, pensions. The NHS workforce is highly regulated — pay scales are set nationally (Agenda for Change) and are not easily reduced.
- **Non-pay (~25–30%)**: Clinical supplies, drugs, utilities, estates, clinical negligence premiums (paid to NHS Resolution).
- **Depreciation (~5–7%)**: Amortisation of buildings, medical equipment, and IT assets.

### What is financial sustainability for an NHS Trust?

An NHS Trust is financially sustainable if it can cover all its costs from its income. This is measured by:

- **Operating surplus/deficit** — whether income exceeds expenditure after all running costs
- **EBITDA margin** — earnings before interest, tax, depreciation and amortisation as a % of income; the industry standard measure of operational sustainability
- **Net surplus margin** — bottom-line surplus after finance costs and PDC dividends

Regulatory expectations:
- EBITDA margin ≥ 2% = financially sustainable (Green)
- EBITDA margin 0–2% = at risk (Amber)
- EBITDA margin < 0% = in deficit, subject to regulatory intervention (Red)

---

## 3. The Financial Crisis in NHS Trusts

### Why this project matters

The NHS faced severe financial pressure in 2022–2024 due to:

1. **Post-COVID cost base**: COVID-19 left the NHS with increased costs from infection control, backlog recovery (extra capacity), and long-term service changes. These costs did not fully unwind.

2. **Inflation surge (2022–2023)**: Energy, clinical supplies, drugs and agency staff costs rose sharply with general inflation, at a rate faster than NHS income grew.

3. **Pay awards**: The government agreed above-inflation pay increases (averaging 5–6%) for NHS staff in 2022/23 and 2023/24, only partially funded by NHS England — leaving Trusts to absorb a gap.

4. **Agency staffing**: Staff shortages drove reliance on expensive agency and bank staff, which carries a 30–50% price premium over substantive (directly employed) staff.

5. **Clinical negligence premiums**: The NHS Resolution premium (mandatory insurance against clinical negligence claims) grew significantly — Trusts cannot control this cost.

### The financial story in numbers

The data in this project quantifies this crisis precisely:

| Year | Total income | Total expenditure | Sector balance | Trusts in deficit |
|------|-------------|-------------------|---------------|-------------------|
| 2021/22 | £110.3bn | £108.7bn | **+£1.6bn surplus** | 37 of 211 (18%) |
| 2022/23 | £118.4bn | £118.2bn | **+£148m surplus** | 85 of 207 (41%) |
| 2023/24 | £129.2bn | £130.8bn | **−£1.6bn deficit** | 124 of 206 (60%) |

In just two years, the NHS Trust sector moved from a **£1.6bn surplus** to a **£1.6bn deficit** — a **£3.2bn swing**. By 2023/24, **60% of all NHS Trusts were running at a loss**.

---

## 4. The Data Source — NHS TAC Publications

### What is TAC?

**TAC** stands for **Trust Accounts Consolidation** — the annual process by which NHS England collects the audited financial accounts of every NHS Trust and Foundation Trust, consolidates them, and publishes the results.

Every NHS Trust submits its annual accounts in a standardised Excel template to NHS England. NHS England publishes the consolidated datasets as public data. This is the authoritative source of NHS Trust financial data.

**Publication URL:** NHS England Finance Returns Publications — TAC section

### What files exist?

For each financial year, NHS England publishes two files:

| File | Contents | Size |
|------|----------|------|
| `TAC_NHS_trusts_YYYY-YY.xlsx` | All 66 NHS Trusts | ~18MB |
| `TAC_NHS_foundation_trusts_YYYY-YY.xlsx` | All 140 Foundation Trusts | ~36MB |

This project uses **6 files** covering 3 years (2021/22, 2022/23, 2023/24):

```
data/raw/
├── TAC_NHS_trusts_2021-22.xlsx                    (16MB — 66 NHS Trusts)
├── TAC_NHS_foundation_trusts_2021-22.xlsx          (33MB — 140 Foundation Trusts)
├── TAC_NHS_trusts_2022-23.xlsx                    (20MB — 66 NHS Trusts)
├── TAC_NHS_foundation_trusts_2022-23.xlsx          (36MB — 140 Foundation Trusts)
├── TAC_NHS_trusts_2023-24.xlsx                    (18MB — 66 NHS Trusts)
└── TAC_NHS_foundation_trusts_2023-24.xlsx          (38MB — 140 Foundation Trusts)
```

### What is in each file?

Each file contains multiple sheets. Two sheets matter for this project:

**Sheet 1 — "List of Providers"**: A lookup table mapping each Trust's full legal name to its ODS code, region, and sector.

| Column | Example |
|--------|---------|
| Full name of Provider | `Barts Health NHS Trust` |
| NHS code | `R1H` |
| Region | `London` |
| Sector | `Acute` |

**Sheet 2 — "All data"**: The actual financial data in **long/narrow format** — every financial line for every Trust in one table with exactly 7 columns.

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| OrganisationName | Text | Full trust name | `Barts Health NHS Trust` |
| WorkSheetName | Text | TAC schedule (which financial statement) | `TAC02 SoCI` |
| TableID | Integer | Table number within that schedule | `1` |
| MainCode | Text | Column reference encoding year type and table | `A02CY01` |
| RowNumber | Integer | Row position in the original form | `12` |
| SubCode | Text | Unique line item identifier | `SCI0100A` |
| Total | Integer | Value in **£000s** (£ thousands) | `350689` |

### What is a SubCode?

A SubCode is the most granular identifier in the dataset — it uniquely identifies a single financial line item within a single TAC schedule. For example:

| SubCode | Meaning |
|---------|---------|
| `SCI0100A` | Operating income from patient care activities (TAC02 — the P&L) |
| `SCI0125A` | Total operating expenses (TAC02) |
| `SCI0140A` | Operating surplus/(deficit) (TAC02) |
| `SCI0240` | Net surplus/(deficit) for the year (TAC02) |
| `EXP0130` | Staff and executive directors costs (TAC08 — Expenditure schedule) |
| `EXP0170` | Drugs costs (TAC08) |
| `STA0250` | Total staff costs (TAC09 — Workforce schedule) |
| `STA0410` | Total average WTE (whole-time equivalent headcount) |

For a Trust like Barts Health NHS Trust (`R1H`), in financial year 2023/24, there are approximately **10,000+ rows** in the "All data" sheet — one for each SubCode across all 19 TAC schedules.

### What is the MainCode convention?

Every row has a MainCode that identifies which column of the original TAC spreadsheet it came from:

```
Format: A{sheet_number}{CY|PY}{table_number}

Examples:
  A02CY01  →  Sheet TAC02 (SoCI),  Current Year,  Table 1
  A09CY01P →  Sheet TAC09 (Staff), Current Year,  Table 1, Permanent staff column
  A08PY01  →  Sheet TAC08 (OpExp), Prior Year,    Table 1
```

**Important:** Each annual file contains **both Current Year (CY) and Prior Year (PY) data**. The 2023/24 file contains all of 2023/24 (CY) AND all of 2022/23 again (PY) — because the accounts show both years side by side for comparison. To avoid double-counting when combining 3 years of files, the pipeline keeps **CY rows only**.

### What TAC schedules are there?

| Schedule | Full Name | Key Data |
|----------|-----------|----------|
| TAC02 SoCI | Statement of Comprehensive Income | Income and expenditure summary (the P&L) |
| TAC03 SoFP | Statement of Financial Position | Balance sheet (assets, liabilities, equity) |
| TAC05 SoCF | Statement of Cash Flows | Cash movements |
| TAC06 Op Inc 1 | Operating Income — Patient Care | Income by activity type and commissioner source |
| TAC07 Op Inc 2 | Operating Income — Other | Research, education, commercial income |
| TAC08 Op Exp | Operating Expenditure | Pay, drugs, supplies, clinical negligence, depreciation |
| TAC09 Staff | Staff Costs and Workforce | Pay by staff group, WTE headcount |
| TAC11 Finance | Finance and Other | Interest, PDC dividends, impairments |
| TAC14 PPE | Property, Plant and Equipment | Fixed assets |
| TAC18 Receivables | Debtors | Money owed to the Trust |
| TAC20 Payables | Creditors | Money the Trust owes |

---

## 5. The Data Model — How the Data is Structured

### Why is the data in long/narrow format?

NHS England designed the TAC format as a **long/narrow** (tidy) dataset rather than a wide spreadsheet. Instead of one column per financial line item per trust, there is **one row per line item per trust**. This makes:

- Adding new financial lines easy (no schema change needed)
- Multi-year comparison consistent
- SQL aggregation straightforward

A consequence: to get the income and expenditure for one Trust in one year, you need to **pivot** the data (filter by SubCode and aggregate). This is what the SQL views do.

### The star schema

The project uses a **star schema** — a standard data warehouse pattern with one central fact table and several surrounding dimension tables.

```
                    ┌─────────────────┐
                    │   dim_trust     │
                    │ org_code (PK)   │
                    │ organisation_   │
                    │ _name           │
                    │ sector          │
                    │ region          │
                    │ trust_type      │
                    └────────┬────────┘
                             │ 1
                             │
    ┌────────────────┐   N   │   N   ┌──────────────────────┐
    │dim_financial   ├───────┤───────┤       fct_tac        │
    │_year           │       │       │ (2,179,740 rows)     │
    │financial_year  │       │       │ org_code (FK)        │
    │(PK)            │       │       │ financial_year (FK)  │
    │start_date      │       │       │ worksheet_name (FK)  │
    │end_date        │       │       │ sub_code (FK)        │
    └────────────────┘       │       │ total_000s           │
                             │       │ main_code            │
    ┌────────────────┐   N   │   1   │ trust_type           │
    │dim_worksheet   ├───────┘       └──────────────────────┘
    │worksheet_name  │
    │(PK)            │
    │schedule_title  │
    │category        │
    └────────────────┘
```

### The fact table: `fct_tac`

This is the central table with **2,179,740 rows** — one row for every SubCode value, for every Trust, for every year.

| Column | Type | Description |
|--------|------|-------------|
| `org_code` | CHAR(3) | ODS code (e.g. `R1H` for Barts) |
| `financial_year` | CHAR(7) | e.g. `2023/24` |
| `worksheet_name` | VARCHAR | e.g. `TAC02 SoCI` |
| `main_code` | VARCHAR | e.g. `A02CY01` |
| `sub_code` | VARCHAR | e.g. `SCI0100A` |
| `total_000s` | DECIMAL | Value in £000s |
| `trust_type` | VARCHAR | `NHS_TRUST` or `FOUNDATION_TRUST` |

A unique constraint on `(org_code, financial_year, main_code, sub_code)` prevents duplicate loading.

### How to read a trust's income from fct_tac

To get Barts Health's patient care income for 2023/24:

```sql
SELECT total_000s
FROM fct_tac
WHERE org_code        = 'R1H'
  AND financial_year  = '2023/24'
  AND sub_code        = 'SCI0100A';  -- Patient care income line in TAC02
-- Returns: 2,047,000  (i.e. £2.047bn)
```

The analytical views do this pivoting for all 206 Trusts simultaneously.

---

## 6. The Database Architecture

The project uses a **two-database pattern** — a standard approach in data engineering:

```
┌────────────────────────────────────────────────────────────────┐
│  nhs_stg  (Staging database)                                   │
│                                                                 │
│  stg_tac_raw          — Raw data from "All data" sheet         │
│  stg_provider_list    — Trust name → ODS code mapping          │
│                                                                 │
│  Purpose: Holds data exactly as it arrived. Safe to truncate   │
│  and reload. Acts as a buffer between source files and the      │
│  analytics layer.                                              │
└────────────────────────────────────────────────────────────────┘
                              │
                              │  Python pipeline joins and
                              │  promotes data to fact table
                              ▼
┌────────────────────────────────────────────────────────────────┐
│  nhs_finance  (Analytics database)                             │
│                                                                 │
│  Dimensions:                                                    │
│    dim_trust          — 215 Trusts with sector, region         │
│    dim_financial_year — 5 years seeded (2019/20 – 2023/24)    │
│    dim_worksheet      — 19 TAC schedules with descriptions     │
│    dim_subcode        — 59 key SubCodes with descriptions      │
│                                                                 │
│  Fact:                                                          │
│    fct_tac            — 2,179,740 rows of financial data       │
│                                                                 │
│  Analytical Views:                                              │
│    v_income_expenditure      — I&E per trust per year          │
│    v_expenditure_breakdown   — Pay / non-pay / drugs split     │
│    v_workforce               — Staff costs and WTE             │
│    v_kpis                    — Computed KPIs per trust per year│
│    v_trust_annual_scorecard  — Wide view, all metrics in one   │
│                                                                 │
│  Purpose: Clean, conformed, analytics-ready. Views compute     │
│  all KPIs. This is what Power BI connects to.                  │
└────────────────────────────────────────────────────────────────┘
```

### Why separate staging and analytics?

- **Idempotency**: If you reload 2023/24 data, the staging DELETE+INSERT clears old data before loading new. The fact table then uses UPSERT (`INSERT ... ON DUPLICATE KEY UPDATE`) to safely overwrite without creating duplicates.
- **Auditability**: Staging preserves the raw source data exactly as it arrived, separate from any transformation.
- **Debugging**: If something goes wrong in the pipeline, you can inspect staging data to identify whether the problem is in the source files or in the transformation logic.

---

## 7. The Data Pipeline

### Overview

```
NHS England website
       │
       │  (manual download — files are large, require agreement to terms)
       ▼
data/raw/*.xlsx   (6 files, ~170MB total)
       │
       │  python/ingestion/load_tac_data.py
       ▼
nhs_stg.stg_tac_raw              (raw data, ~2.1m rows)
nhs_stg.stg_provider_list        (trust name→ODS code mapping)
       │
       │  (still in load_tac_data.py — promote_to_fact() function)
       ▼
nhs_finance.dim_trust            (215 trusts)
nhs_finance.fct_tac              (2,179,740 rows)
       │
       │  python/reporting/export_for_powerbi.py
       ▼
data/processed/powerbi_export/*.csv   (8 CSV files, ready for Power BI)
```

### Step-by-step pipeline walkthrough

#### Step 1 — Read the provider list

Each Excel file has a "List of Providers" sheet. The pipeline reads this to get the ODS code (e.g. `R1H`) for each Trust. This is needed because the "All data" sheet only contains the Trust's full name — not the 3-character code.

```python
# Read provider list → normalise column names → filter to valid ODS codes
df = pd.read_excel(path, sheet_name="List of Providers", header=0)
df = df.rename(columns={"Full name of Provider": "organisation_name", "NHS code": "org_code", ...})
df = df[df["org_code"].str.len() == 3]  # ODS codes are exactly 3 characters
```

#### Step 2 — Read the "All data" sheet

The main data sheet. The pipeline:
- Handles two different column name formats (2021/22 used "Organisation Name" with a space; later years use "OrganisationName")
- Filters to Current Year (CY) rows only — rows where `MainCode` does NOT contain "PY"
- Converts the `Total` column to integer (the raw Excel column contains commas in some file versions)

```python
# Normalise column names across file versions
col_map = {
    "Organisation Name": "OrganisationName",   # 2021/22 format
    "Value number":      "Total",               # 2021/22 format
}
df = df.rename(columns=col_map)

# Keep only Current Year rows
df["year_type"] = df["main_code"].apply(lambda c: "PY" if "PY" in str(c) else "CY")
df = df[df["year_type"] == "CY"]
```

#### Step 3 — Validate

Before writing to the database, the pipeline checks:
- No null values in critical columns (`organisation_name`, `sub_code`, `total`)
- No duplicate rows within the file
- All organisation names appear in the provider list (warns if any are unmatched)

If critical validation fails, the pipeline raises an error and stops before writing anything.

#### Step 4 — Load to staging

Data is written to `nhs_stg` using pandas `to_sql`. Before inserting, existing rows for this year and trust type are deleted — making each run idempotent (safe to re-run without creating duplicates).

```python
conn.execute(text("DELETE FROM stg_tac_raw WHERE financial_year = :fy AND trust_type = :tt"), ...)
data_df.to_sql("stg_tac_raw", engine, if_exists="append", index=False, chunksize=2000)
```

#### Step 5 — Join to get ODS codes and promote to fact

The "All data" sheet only has organisation names, not ODS codes. The pipeline joins staging data to the provider list to resolve each name to its 3-character ODS code, then upserts into `fct_tac`:

```sql
SELECT p.org_code, r.*
FROM stg_tac_raw r
JOIN stg_provider_list p
    ON r.organisation_name = p.organisation_name
   AND r.financial_year    = p.financial_year
   AND r.trust_type        = p.trust_type
```

The UPSERT (`INSERT ... ON DUPLICATE KEY UPDATE`) means the fact table is safe to reload — existing rows are updated rather than duplicated.

#### Step 6 — Upsert dimension tables

`dim_trust` is upserted from the provider list: new trusts are inserted, existing trust details (sector, region) are updated if they have changed. The `first_year_seen` and `last_year_seen` columns track when each Trust first and last appeared in the dataset.

#### Processing all 6 files

The pipeline discovers all matching Excel files in `data/raw/` automatically (pattern `TAC_NHS_*.xlsx`) and processes them in order. Total runtime: approximately **10–15 minutes** for all 6 files.

```
Found 6 files to process
Processing: TAC_NHS_foundation_trusts_2021-22.xlsx  [1/6]
Processing: TAC_NHS_foundation_trusts_2022-23.xlsx  [2/6]
...
COMPLETE
  dim_trust rows : 215
  fct_tac rows   : 2,179,740
```

---

## 8. The Analytics Layer — SQL Views

The raw fact table contains 2.18 million rows of individual SubCode values. The views transform these into meaningful analytical tables by **pivoting** SubCodes into columns.

### v_income_expenditure

Pivots TAC02 SoCI (Statement of Comprehensive Income) SubCodes into an I&E summary row per Trust per year.

```sql
-- For each trust and year, take the values for these specific SubCodes:
MAX(CASE WHEN sub_code = 'SCI0100A' THEN total_000s END)  AS patient_care_income_000s
MAX(CASE WHEN sub_code = 'SCI0110A' THEN total_000s END)  AS other_income_000s
MAX(CASE WHEN sub_code = 'SCI0140A' THEN total_000s END)  AS operating_surplus_000s
MAX(CASE WHEN sub_code = 'SCI0240'  THEN total_000s END)  AS net_surplus_000s
```

**Output:** 624 rows (208 average trusts × 3 years)

### v_expenditure_breakdown

Pivots TAC08 Operating Expenditure SubCodes. Uses `dim_subcode.analytics_category` to group lines into Pay, Non-Pay, and Depreciation/Amortisation buckets.

```sql
SUM(CASE WHEN sc.analytics_category = 'PAY'    THEN total_000s END)  AS pay_000s
SUM(CASE WHEN sc.analytics_category = 'NON_PAY' THEN total_000s END) AS non_pay_000s
```

### v_workforce

Pivots TAC09 Staff SubCodes into staff cost and WTE columns per Trust per year.

### v_kpis

Joins the above three views and computes derived KPIs:

```sql
-- EBITDA = Operating surplus + depreciation/amortisation
operating_surplus_000s + COALESCE(depreciation_amort_000s, 0) AS ebitda_000s

-- EBITDA margin as a % of total income
ROUND(ebitda_000s / NULLIF(total_income_000s, 0) * 100, 1) AS ebitda_margin_pct

-- Pay as % of income
ROUND(pay_000s / NULLIF(total_income_000s, 0) * 100, 1) AS pay_pct_income

-- Cost per WTE (£000s per WTE)
ROUND(staff_cost_000s / NULLIF(total_wte, 0), 1) AS cost_per_wte_000s
```

### v_trust_annual_scorecard

The master analytical view — a single wide table combining all metrics, income detail, expenditure detail, and computed RAG flags. This is the primary source for Power BI.

```sql
-- RAG flags (pre-computed for fast dashboard filtering)
CASE WHEN ebitda_margin_pct < 2  THEN 'Red'
     WHEN ebitda_margin_pct < 5  THEN 'Amber'
     ELSE 'Green' END AS ebitda_rag,

CASE WHEN operating_surplus_000s < 0 THEN 1 ELSE 0 END AS is_deficit
```

---

## 9. Key Performance Indicators (KPIs)

These are the core financial health metrics used throughout the NHS and in this project:

### EBITDA Margin %

**What it measures:** Operational profitability — how much of every pound of income is left after paying staff and non-pay running costs, before accounting for interest, tax, depreciation and amortisation.

**Why EBITDA and not net surplus?** Depreciation is a non-cash charge that reflects the aging of buildings and equipment — it doesn't represent cash actually leaving the organisation. EBITDA strips this out to give a cleaner view of operational cashflow generation. This is the standard NHS sustainability metric.

```
EBITDA = Operating Surplus + Depreciation + Amortisation

EBITDA Margin % = EBITDA / Total Income × 100
```

| RAG | Threshold | Meaning |
|-----|-----------|---------|
| Green | ≥ 5% | Strong financial position |
| Amber | 2–5% | Financially fragile |
| Red | < 2% | Unsustainable; regulatory risk |

**2023/24 average by sector:**
- Specialist: 4.7% (best performing)
- Community: 4.9%
- Ambulance: 4.2%
- Mental Health: 3.5%
- Acute: 3.3% (largest sector, under most pressure)

### Pay as % of Income

**What it measures:** How much of total income is consumed by staff costs. In the NHS, workforce is the largest cost driver and the least controllable (national pay scales, shortage specialties, agency dependency).

```
Pay % = Total Pay Costs / Total Income × 100
```

**Benchmarks:**
- Acute: ~60–65% (lower because high income from activity)
- Ambulance / Community / Mental Health: 70–75% (more labour-intensive models)

### Net Surplus Margin %

The bottom line: surplus/(deficit) as a % of income after ALL costs including finance charges and PDC dividends.

```
Net Surplus Margin % = Net Surplus (Deficit) / Total Income × 100
```

In 2023/24, the acute sector averaged **-5.2% net surplus margin** — meaning for every £100 of income, acute Trusts spent £105.20.

### Cost per WTE (£000s)

Average cost per whole-time equivalent member of staff.

```
Cost per WTE = Total Staff Costs / Total WTE
```

Useful for benchmarking staff cost efficiency across Trusts of different sizes. A higher cost per WTE may reflect: more senior staff mix, London weighting, or agency staff premium.

### Other KPIs available in the dataset

| KPI | Description |
|-----|-------------|
| Private patient income % | Commercial revenue as % of total (typically 1–5%) |
| Drugs cost % | High cost drugs as % of income (important for specialist Trusts) |
| Clinical negligence % | NHS Resolution premium as % of income (growing cost pressure) |
| Finance income vs expense | Net finance position (capital structure) |

---

## 10. Key Findings from the Data

### Finding 1: The NHS sector tipped into collective deficit in 2023/24

The most striking finding is the scale and speed of the financial deterioration:

```
2021/22  →  +£1,600m surplus  (18% of trusts in deficit)
2022/23  →  +£148m surplus    (41% of trusts in deficit)
2023/24  →  −£1,634m deficit  (60% of trusts in deficit)
```

This is not a gradual decline — it is a sharp deterioration driven by inflation and pay pressures that outpaced income growth.

### Finding 2: Income is growing, but expenditure is growing faster

| | 2021/22 | 2023/24 | Growth |
|--|---------|---------|--------|
| Income | £110.3bn | £129.2bn | +17.1% |
| Expenditure | £108.7bn | £130.8bn | +20.3% |

Expenditure grew 3.2 percentage points faster than income over 2 years.

### Finding 3: The acute sector carries the highest absolute pressure

Acute Trusts represent **76% of NHS income** (£98bn of £129bn in 2023/24) and account for **74 of the 124 deficit Trusts**. Their average EBITDA margin fell from 4.8% to 3.3%.

### Finding 4: Specialist Trusts are the most financially resilient

Specialist Trusts (Great Ormond Street, Royal Marsden, etc.) maintained:
- Highest EBITDA margin: 4.7% in 2023/24
- Lowest pay % of income: 55.2% (more non-pay clinical costs like high-cost drugs)
- Only 6 of 15 in deficit

Their income model (nationally commissioned, highly specialised, less exposed to block contract reductions) provides more stability.

### Finding 5: Mental Health saw the sharpest relative deterioration

Mental Health Trusts had the worst net surplus margin in 2023/24 at **-2.4%** on average, and 28 of 45 (62%) in deficit. Their workforce is almost entirely pay (70.6% of income), giving very little headroom to absorb cost pressures.

### Finding 6: Pay pressure is sector-wide

Across all sectors, pay costs as a % of income remained elevated at 65–72% — substantially above pre-COVID norms. The 2022 and 2023 pay awards added c.5–6% to the national pay bill in each year, with NHS England funding only approximately 60–70% of the cost centrally.

---

## 11. The Power BI Dashboard

### What Power BI is

Microsoft Power BI is a business intelligence tool that connects to data sources (CSVs, databases, APIs) and produces interactive visual dashboards. It is the standard reporting tool in NHS finance departments.

### How this project feeds Power BI

The Python export script (`python/reporting/export_for_powerbi.py`) pulls data from the MySQL views and writes 8 CSV files to `data/processed/powerbi_export/`. These CSVs are the data source for Power BI.

Alternative: Power BI can connect directly to MySQL via a connector — the views are designed for this (DirectQuery mode).

### Data model in Power BI

Power BI uses relationships between tables, equivalent to SQL JOINs:

```
kpis[org_code]        → dim_trust[org_code]        (many-to-one)
kpis[financial_year]  → dim_financial_year[financial_year]  (many-to-one)
```

Slicers on `dim_trust[sector]`, `dim_trust[region]`, and `dim_financial_year[financial_year]` filter all visuals simultaneously.

### The 5 planned dashboard pages

| Page | Purpose |
|------|---------|
| **Executive Summary** | KPI cards, sector breakdown, deficit/surplus donut, 3-year trend lines |
| **Income & Expenditure** | Waterfall bridge, trust-level matrix, scatter plots |
| **Expenditure Detail** | Pay vs non-pay breakdown, drugs costs, clinical negligence trend |
| **Benchmarking** | EBITDA distribution, top/bottom performers, peer comparison table |
| **Workforce** | WTE trends, cost per WTE, staff cost as % of income |

### DAX measures (the Power BI calculation language)

DAX (Data Analysis Expressions) is how Power BI computes values dynamically based on the current filter context. Key measures:

```dax
-- Total income, converting from £000s to £millions
Total Income (£m) =
DIVIDE(SUMX(ie_summary, ie_summary[total_income_000s]), 1000, 0)

-- EBITDA margin as a percentage
EBITDA Margin % =
DIVIDE(
    SUMX(kpis, kpis[ebitda_000s]),
    SUMX(kpis, kpis[total_income_000s]),
    0
) * 100

-- Count of trusts currently in deficit (filtered by slicer)
Deficit Trusts =
COUNTROWS(FILTER(kpis, kpis[operating_surplus_000s] < 0))
```

---

## 12. Project File Structure

```
31-Portfolio-NHS-Analystics/
│
├── README.md                          ← Quick-start summary
├── PROJECT_DOCUMENTATION.md           ← This file
├── CLAUDE.md                          ← AI coding assistant instructions
│
├── agent_docs/                        ← Domain knowledge reference
│   ├── data_dictionary.md             ← TAC columns and SubCode reference
│   ├── kpi_definitions.md             ← KPI formulas and RAG thresholds
│   └── report_calendar.md             ← NHS period table and reporting cycle
│
├── data/
│   ├── raw/                           ← Source NHS Excel files (not committed to git)
│   │   ├── TAC_NHS_trusts_2021-22.xlsx
│   │   ├── TAC_NHS_foundation_trusts_2021-22.xlsx
│   │   ├── TAC_NHS_trusts_2022-23.xlsx
│   │   ├── TAC_NHS_foundation_trusts_2022-23.xlsx
│   │   ├── TAC_NHS_trusts_2023-24.xlsx
│   │   └── TAC_NHS_foundation_trusts_2023-24.xlsx
│   └── processed/
│       └── powerbi_export/            ← 8 CSV files for Power BI
│           ├── dim_trust.csv
│           ├── dim_financial_year.csv
│           ├── ie_summary.csv
│           ├── expenditure_breakdown.csv
│           ├── workforce.csv
│           ├── kpis.csv
│           ├── income_detail.csv
│           ├── expenditure_detail.csv
│           └── sector_benchmarks.csv
│
├── python/
│   ├── CLAUDE.md                      ← Python layer coding standards
│   ├── ingestion/
│   │   └── load_tac_data.py           ← Main ingestion script (Stage 1)
│   ├── reporting/
│   │   └── export_for_powerbi.py      ← CSV export script (Stage 3)
│   └── transformation/                ← (future: intermediate transforms)
│
├── sql/
│   ├── CLAUDE.md                      ← SQL layer coding standards
│   ├── schema/
│   │   ├── create_tables_mysql.sql    ← Full schema: staging + dims + fact + views
│   │   └── create_tables.sql          ← PostgreSQL equivalent (reference)
│   ├── views/
│   │   ├── v_validation_checks.sql    ← 10 data quality checks with expected values
│   │   └── v_trust_annual_scorecard.sql ← Master wide-view for Power BI
│   └── analysis/
│       └── sector_trend_analysis.sql  ← 10 presentation-ready analytical queries
│
├── power_bi/
│   ├── CLAUDE.md                      ← Power BI coding standards
│   └── setup_guide.md                 ← Model relationships, DAX, page specs
│
└── reports/
    └── CLAUDE.md                      ← Report narrative standards (FReM)
```

---

## 13. How to Reproduce This Project

### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Python | 3.11+ | Pipeline scripts |
| MySQL | 8.0+ | Database |
| pip packages | see below | Python dependencies |

```bash
pip install pandas sqlalchemy pymysql openpyxl
```

### Step 1: Create the database schema

Open `sql/schema/create_tables_mysql.sql` in DbVisualizer (or MySQL Workbench) and execute the entire script. This:
- Creates the `nhs_stg` and `nhs_finance` databases
- Creates all tables with indexes and constraints
- Seeds dimension tables (dim_financial_year, dim_worksheet, dim_subcode) with reference data
- Creates all analytical views

**Expected output:** 2 databases, 7 tables, 5 views, 84 seed rows in dimension tables.

### Step 2: Download NHS data files

Download the 6 TAC Excel files from NHS England's TAC publications page (search: "NHS England Trust Accounts Consolidation"). Save them to `data/raw/` with these exact names:

```
TAC_NHS_trusts_2021-22.xlsx
TAC_NHS_foundation_trusts_2021-22.xlsx
TAC_NHS_trusts_2022-23.xlsx
TAC_NHS_foundation_trusts_2022-23.xlsx
TAC_NHS_trusts_2023-24.xlsx
TAC_NHS_foundation_trusts_2023-24.xlsx
```

### Step 3: Run the ingestion pipeline

```bash
python python/ingestion/load_tac_data.py
```

This processes all 6 files in order. Expected runtime: 10–15 minutes. Expected output:

```
Found 6 files to process
[Processing each file with progress logs]
COMPLETE
  dim_trust rows : 215
  fct_tac rows   : 2,179,740
```

### Step 4: Validate the data

Run `sql/views/v_validation_checks.sql` in DbVisualizer. All 10 queries have inline comments showing expected values. Key checks:

- Query 2: Patient care income should be £99.8bn (2021/22) → £117.9bn (2023/24)
- Query 5: ~60% of trusts in deficit in 2023/24
- Query 10: `total_rows` should equal `unique_keys` (no duplicates)

### Step 5: Export for Power BI

```bash
python python/reporting/export_for_powerbi.py
```

Writes 8 CSV files to `data/processed/powerbi_export/`. Expected runtime: ~30 seconds.

### Step 6: Build the Power BI dashboard

Follow `power_bi/setup_guide.md`:
1. Open Power BI Desktop
2. Get Data → Text/CSV → import all 8 CSVs
3. In Model view, create the relationships listed in the guide
4. Create a blank table named "Measures" and add all DAX measures
5. Build the 5 report pages

---

## 14. NHS Glossary

| Term | Definition |
|------|-----------|
| **Agenda for Change (AfC)** | The national pay framework for NHS staff (Bands 1–9). Most clinical and administrative staff are on AfC. |
| **API** | Aligned Payment and Incentive — the NHS contract mechanism under which commissioners pay Trusts. Replaced PbR from 2021/22. |
| **CIP** | Cost Improvement Programme — an NHS Trust's annual efficiency savings plan, typically 2–5% of expenditure. |
| **Commissioner** | An organisation that buys (commissions) NHS services. Mainly ICBs (formerly CCGs) and NHS England for specialised services. |
| **EBITDA** | Earnings Before Interest, Tax, Depreciation and Amortisation. The standard NHS operational sustainability measure. |
| **FReM** | Financial Reporting Manual — the UK government accounting standards that NHS Trusts must follow (based on IFRS). |
| **FT** | Foundation Trust — an NHS Trust that has earned greater operational and financial autonomy. |
| **ICB** | Integrated Care Board — replaced Clinical Commissioning Groups (CCGs) from July 2022. Commissions most NHS services locally. |
| **IFRS** | International Financial Reporting Standards — the accounting framework adopted by NHS Trusts from 2009. |
| **NHS Resolution** | The arm's-length body that manages clinical negligence claims against the NHS. Trusts pay an annual premium. |
| **ODS code** | Organisation Data Service code — a 3-character alphanumeric code uniquely identifying each NHS organisation (e.g. `R1H` = Barts Health). |
| **PDC dividend** | Public Dividend Capital dividend — a return paid by NHS Trusts to the government on publicly funded assets (similar to a cost of capital charge). |
| **PFI** | Private Finance Initiative — a financing mechanism where private companies built NHS facilities and the Trust pays annual charges over 25–30 years. |
| **Provider** | An NHS Trust or Foundation Trust that delivers (provides) healthcare services. |
| **SoCI** | Statement of Comprehensive Income — the NHS equivalent of a Profit & Loss account. |
| **SoFP** | Statement of Financial Position — the NHS equivalent of a Balance Sheet. |
| **SoCF** | Statement of Cash Flows — shows how cash moved in and out of the organisation. |
| **Surplus / Deficit** | Whether the Trust's income exceeded expenditure (surplus) or not (deficit) in the year. |
| **TAC** | Trust Accounts Consolidation — NHS England's annual process of collecting and publishing all Trust financial accounts. |
| **WTE** | Whole-Time Equivalent — a measure of workforce size adjusted for part-time working. 2 staff each working 50% = 1.0 WTE. |

---

*Document prepared as part of the NHS Trust Financial Analytics portfolio project.*
*Data source: NHS England Trust Accounts Consolidation (TAC) — public domain.*
*All financial figures from audited NHS Trust annual accounts, published by NHS England.*
