# SQL Layer — Standards and Conventions

## Database Target

- Engine: **PostgreSQL 15** (local dev) / Azure SQL (production equivalent)
- Default schema: `nhs_finance`
- Staging schema: `nhs_stg`

## Schema Layout

```
nhs_stg.*        # Raw ingested data, 1:1 with source files
nhs_finance.*    # Cleaned, typed, conformed tables
nhs_finance.v_*  # Analytical views built on top of finance tables
```

## Table Naming

| Layer      | Prefix  | Example                          |
|------------|---------|----------------------------------|
| Staging    | `stg_`  | `stg_provider_finance`           |
| Dimension  | `dim_`  | `dim_trust`, `dim_period`        |
| Fact       | `fct_`  | `fct_income_expenditure`         |
| View       | `v_`    | `v_cost_per_wte`                 |
| Procedure  | `sp_`   | `sp_load_finance_period`         |

## Core Tables

### dim_trust
```
org_code        CHAR(3)       PRIMARY KEY   -- ODS code
trust_name      VARCHAR(200)
trust_type      VARCHAR(20)                 -- ACUTE | MENTAL_HEALTH | etc.
icb_code        CHAR(3)
region_name     VARCHAR(100)
is_foundation   BOOLEAN
```

### dim_period
```
period_key      INT           PRIMARY KEY   -- YYYYMM e.g. 202304
financial_year  CHAR(7)                     -- e.g. 2023/24
period_label    CHAR(3)                     -- M01 through M12
month_name      VARCHAR(10)
quarter_label   CHAR(2)                     -- Q1 through Q4
is_year_end     BOOLEAN
```

### fct_income_expenditure
```
ie_id           BIGSERIAL     PRIMARY KEY
org_code        CHAR(3)       REFERENCES dim_trust
period_key      INT           REFERENCES dim_period
account_code    VARCHAR(20)
account_name    VARCHAR(200)
account_type    VARCHAR(20)   -- INCOME | PAY | NON_PAY | CAPITAL
subjective_code VARCHAR(10)
budget_000s     NUMERIC(12,0)
actual_000s     NUMERIC(12,0)
data_type       VARCHAR(10)   -- ACTUAL | FORECAST | PLAN
load_ts         TIMESTAMPTZ   DEFAULT now()
```

### fct_workforce
```
wf_id           BIGSERIAL     PRIMARY KEY
org_code        CHAR(3)       REFERENCES dim_trust
period_key      INT           REFERENCES dim_period
staff_group     VARCHAR(100)  -- e.g. Nursing, Medical, Admin
contract_type   VARCHAR(20)   -- SUBSTANTIVE | BANK | AGENCY
wte_budget      NUMERIC(10,2)
wte_actual      NUMERIC(10,2)
pay_budget_000s NUMERIC(12,0)
pay_actual_000s NUMERIC(12,0)
```

## View Standards

All views must include:
- `financial_year` and `period_label` columns
- `org_code` and `trust_name` (join to dim_trust in the view)
- A `variance_000s` and `variance_pct` column where budget vs actual is relevant

## Query Style

- Use CTEs (`WITH`) for multi-step logic — no nested subqueries beyond 1 level
- Always alias table names: `fct_income_expenditure ie`
- Filter `data_type = 'ACTUAL'` unless the query explicitly includes forecast/plan
- Round percentages to 1 decimal place: `ROUND(value / base * 100, 1)`
- All monetary columns divided or multiplied must stay in £000s — add comment if units change

## Example View Pattern

```sql
-- v_income_expenditure.sql
-- Summary of income and expenditure by Trust and period
-- Monetary values in £000s

CREATE OR REPLACE VIEW nhs_finance.v_income_expenditure AS
WITH actuals AS (
    SELECT
        ie.org_code,
        ie.period_key,
        ie.account_type,
        SUM(ie.budget_000s) AS budget_000s,
        SUM(ie.actual_000s) AS actual_000s,
        SUM(ie.actual_000s - ie.budget_000s) AS variance_000s
    FROM nhs_finance.fct_income_expenditure ie
    WHERE ie.data_type = 'ACTUAL'
    GROUP BY ie.org_code, ie.period_key, ie.account_type
)
SELECT
    t.trust_name,
    a.org_code,
    p.financial_year,
    p.period_label,
    a.account_type,
    a.budget_000s,
    a.actual_000s,
    a.variance_000s,
    ROUND(a.variance_000s::NUMERIC / NULLIF(a.budget_000s, 0) * 100, 1) AS variance_pct
FROM actuals a
JOIN nhs_finance.dim_trust t ON a.org_code = t.org_code
JOIN nhs_finance.dim_period p ON a.period_key = p.period_key;
```

## Do Not

- Do not use `SELECT *` in views or procedures
- Do not use implicit date casts — always `CAST(col AS DATE)` or `::DATE`
- Do not store calculated KPIs in fact tables — compute in views or DAX
- Do not DROP and recreate staging tables; TRUNCATE and INSERT instead
