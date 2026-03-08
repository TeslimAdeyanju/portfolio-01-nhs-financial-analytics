# NHS Trust Financial Analytics — Project Rules

## Client Context

This project models the finance analytics function of an NHS Acute Trust in England.
It covers financial year 2021/22 through 2023/24 using real NHS England public data.

The reporting entity follows:
- NHS Financial Reporting Manual (FReM)
- IFRS as adopted for the public sector
- NHS England Planning and contracting guidance

## Project Structure

```
nhs-trust-financial-analytics/
├── data/raw/          # Source files from NHS England (do not modify)
├── data/processed/    # Cleaned outputs from Python pipeline
├── sql/               # DDL, views, stored procedures
├── python/            # Ingestion, transformation, validation, reporting
├── power_bi/          # .pbix dashboard and DAX measures
├── reports/           # Narrative report templates and outputs
└── agent_docs/        # Data dictionary, KPI definitions, report calendar
```

## Financial Year Convention

- NHS financial year runs 1 April to 31 March
- Label format: `YYYY/YY` e.g. `2023/24`
- Period label format: `M01` through `M12` (April = M01, March = M12)
- Always filter by `financial_year` and `period` columns, not calendar month

## Currency

- All monetary values are in **GBP thousands (£000s)** unless stated otherwise
- Never mix £000s and £m in the same table or visual
- Label all monetary columns with `_000s` suffix in SQL and Python

## NHS Organisational Hierarchy

```
NHS England (national)
  └── Integrated Care Board (ICB) — regional commissioner
        └── NHS Trust / Foundation Trust — provider
              └── Division → Directorate → Cost Centre
```

Key identifiers:
- `org_code`     — 3-character ODS code (e.g. RJ1 = Guy's and St Thomas')
- `trust_name`   — Full legal name
- `icb_code`     — Parent ICB ODS code
- `trust_type`   — `ACUTE` | `MENTAL_HEALTH` | `COMMUNITY` | `AMBULANCE` | `SPECIALIST`

## Core KPIs (defined in agent_docs/kpi_definitions.md)

1. EBITDA Margin %
2. CIP Achievement %
3. Pay as % of Income
4. Cost per WTE
5. Budget Variance %
6. Capital Spend as % of Plan

## Data Sources (agent_docs/data_dictionary.md)

- NHS England Provider Finance Returns (annual)
- NHS Digital Workforce Statistics (monthly WTE)
- NHS England Reference Costs (HRG activity + unit cost)
- NHS England ERIC Estates Returns (capital + estates)

## Naming Conventions

| Layer     | Convention            | Example                        |
|-----------|-----------------------|--------------------------------|
| SQL table | `snake_case`          | `stg_provider_finance`         |
| SQL view  | `v_` prefix           | `v_income_expenditure`         |
| Python fn | `snake_case`          | `calculate_ebitda_margin()`    |
| DAX measure | PascalCase + `[]`   | `[EBITDA Margin %]`            |
| File      | `snake_case`          | `load_trust_returns.py`        |

## Do Not

- Do not hardcode Trust ODS codes — always parameterise
- Do not store raw NHS files in version control (add `data/raw/` to .gitignore)
- Do not mix actuals and forecast in the same fact table row — use `data_type` column
- Do not use calendar year grouping for NHS data
