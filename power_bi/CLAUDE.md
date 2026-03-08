# Power BI Layer — DAX Conventions and Semantic Model Rules

## File

- Main file: `power_bi/NHS_Finance_Dashboard.pbix`
- Data source: PostgreSQL views (`nhs_finance.v_*`) via DirectQuery or imported CSV exports

## Semantic Model Structure

### Tables to import

| Table                     | Source                          | Load mode  |
|---------------------------|---------------------------------|------------|
| Finance                   | `v_income_expenditure`          | Import     |
| Workforce                 | `fct_workforce`                 | Import     |
| Trust                     | `dim_trust`                     | Import     |
| Period                    | `dim_period`                    | Import     |
| Reference Costs           | `v_cost_per_wtu`                | Import     |

### Relationships

```
Finance[org_code]    → Trust[org_code]      (Many-to-One)
Finance[period_key]  → Period[period_key]   (Many-to-One)
Workforce[org_code]  → Trust[org_code]      (Many-to-One)
Workforce[period_key]→ Period[period_key]   (Many-to-One)
```

Cross-filter direction: **Single** on all relationships unless specifically required.

## DAX Conventions

### Measure naming

- Use natural English names with Title Case: `Total Income £000s`
- KPI measures use `%` suffix: `EBITDA Margin %`
- Variance measures use `Var` prefix: `Var vs Budget £000s`
- YTD measures use `YTD` suffix: `Total Pay YTD £000s`

### Measure file organisation (in `dax/` folder)

| File                       | Contains                                      |
|----------------------------|-----------------------------------------------|
| `measures_income.dax`      | Total Income, Clinical Income, Other Income   |
| `measures_expenditure.dax` | Total Pay, Total Non-Pay, Total Expenditure   |
| `measures_variance.dax`    | Variance £000s, Variance %, RAG status        |
| `measures_kpis.dax`        | EBITDA Margin, CIP %, Pay %, Cost per WTE     |
| `measures_ytd.dax`         | YTD versions of all core measures             |

### Standard measure patterns

```dax
-- Base measure pattern
Total Income £000s =
CALCULATE(
    SUM( Finance[actual_000s] ),
    Finance[account_type] = "INCOME",
    Finance[data_type] = "ACTUAL"
)

-- Variance measure pattern
Var vs Budget £000s =
[Total Income £000s] - [Budget Income £000s]

-- Percentage measure pattern
EBITDA Margin % =
DIVIDE( [EBITDA £000s], [Total Income £000s], BLANK() )

-- YTD measure pattern (NHS year starts April = M01)
Total Income YTD £000s =
CALCULATE(
    [Total Income £000s],
    FILTER(
        ALL( Period ),
        Period[financial_year] = SELECTEDVALUE( Period[financial_year] )
        && Period[period_label] <= SELECTEDVALUE( Period[period_label] )
    )
)

-- RAG status measure
Income RAG =
VAR _var = [Var vs Budget %]
RETURN
    SWITCH(
        TRUE(),
        _var >= 0,       "GREEN",
        _var >= -0.02,   "AMBER",
        "RED"
    )
```

## Report Pages

| Page              | Purpose                                      |
|-------------------|----------------------------------------------|
| Executive Summary | High-level KPI cards + YTD vs plan           |
| I&E Deep Dive     | Income and expenditure waterfall + trend      |
| Workforce         | WTE, pay run rate, agency vs substantive      |
| Cost per Activity | Reference cost benchmarking by HRG           |
| Capital           | Capital spend vs plan, backlog maintenance    |
| Trust Benchmarking| Cross-Trust comparison on key KPIs           |

## Visual Standards

- Use the NHS colour palette:
  - NHS Blue: `#005EB8`
  - NHS Dark Blue: `#003087`
  - NHS Green: `#009639`
  - NHS Red (alert): `#DA291C`
  - NHS Amber: `#FFB81C`
- All charts: remove gridlines, keep axis labels clean
- Cards: always show variance vs budget alongside the value
- Tables: conditional formatting for variance columns (red/amber/green)
- No 3D visuals

## Do Not

- Do not create measures inside report visuals — all measures go in the semantic model
- Do not use implicit measures (auto-sum from column drag)
- Do not filter by calendar month — always use `period_label` (M01–M12)
- Do not use SUMX over large tables — pre-aggregate in SQL views
