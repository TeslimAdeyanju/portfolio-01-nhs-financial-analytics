# Power BI Setup Guide — NHS Finance Analytics

## 1. Connect to CSV Files

After running `python python/reporting/export_for_powerbi.py`, import these CSVs from
`data/processed/powerbi_export/`:

| File | Rows | Description |
|------|------|-------------|
| `dim_trust.csv` | 215 | Provider master — org_code, sector, region, trust_type |
| `dim_financial_year.csv` | 5 | Calendar — 2019/20 to 2023/24 |
| `kpis.csv` | 624 | Pre-built KPIs (1 row per trust per year) |
| `ie_summary.csv` | 624 | I&E summary (income, expenditure, surplus) |
| `expenditure_breakdown.csv` | 624 | Pay / non-pay / drugs split |
| `workforce.csv` | 624 | Staff costs and WTE |
| `income_detail.csv` | 9,144 | Income by line item |
| `expenditure_detail.csv` | 11,856 | Expenditure by line item |
| `sector_benchmarks.csv` | 30 | Aggregated sector totals |

### Import steps
1. **Get Data → Text/CSV** → select each file → Load
2. On the **Home** tab, use **Transform Data** to verify column types:
   - `financial_year` → Text
   - `_000s` columns → Whole Number
   - `_pct` columns → Decimal Number
   - `org_code` → Text

---

## 2. Data Model Relationships

In Model view, create these relationships (all single-directional, many-to-one):

```
kpis[org_code]         → dim_trust[org_code]
kpis[financial_year]   → dim_financial_year[financial_year]
ie_summary[org_code]   → dim_trust[org_code]
ie_summary[financial_year] → dim_financial_year[financial_year]
expenditure_breakdown[org_code] → dim_trust[org_code]
expenditure_breakdown[financial_year] → dim_financial_year[financial_year]
workforce[org_code]    → dim_trust[org_code]
workforce[financial_year] → dim_financial_year[financial_year]
income_detail[org_code] → dim_trust[org_code]
income_detail[financial_year] → dim_financial_year[financial_year]
expenditure_detail[org_code] → dim_trust[org_code]
expenditure_detail[financial_year] → dim_financial_year[financial_year]
```

---

## 3. DAX Measures

Create a dedicated **Measures** table (Enter Data → blank table named "Measures").

### Core I&E Measures

```dax
Total Income (£m) =
DIVIDE(
    SUMX(ie_summary, ie_summary[total_income_000s]),
    1000, 0
)

Total Expenditure (£m) =
DIVIDE(
    SUMX(ie_summary, ie_summary[total_expenditure_000s]),
    1000, 0
)

Operating Surplus (£m) =
DIVIDE(
    SUMX(ie_summary, ie_summary[operating_surplus_000s]),
    1000, 0
)

Net Surplus (£m) =
DIVIDE(
    SUMX(ie_summary, ie_summary[net_surplus_000s]),
    1000, 0
)
```

### KPI Measures

```dax
EBITDA Margin % =
DIVIDE(
    SUMX(kpis, kpis[ebitda_000s]),
    SUMX(kpis, kpis[total_income_000s]),
    0
) * 100

Pay % of Income =
DIVIDE(
    SUMX(kpis, kpis[pay_000s]),
    SUMX(kpis, kpis[total_income_000s]),
    0
) * 100

Net Surplus Margin % =
DIVIDE(
    SUMX(ie_summary, ie_summary[net_surplus_000s]),
    SUMX(ie_summary, ie_summary[total_income_000s]),
    0
) * 100

Deficit Trusts =
COUNTROWS(
    FILTER(kpis, kpis[operating_surplus_000s] < 0)
)

Surplus Trusts =
COUNTROWS(
    FILTER(kpis, kpis[operating_surplus_000s] >= 0)
)
```

### Year-on-Year Variance

```dax
-- Requires a slicer on dim_financial_year[financial_year]
Prior Year Income (£m) =
VAR CurrentYear = SELECTEDVALUE(dim_financial_year[financial_year])
VAR PriorYear   =
    SWITCH(CurrentYear,
        "2023/24", "2022/23",
        "2022/23", "2021/22",
        "2021/22", "2020/21",
        BLANK()
    )
RETURN
    IF(
        NOT ISBLANK(PriorYear),
        CALCULATE(
            DIVIDE(SUM(ie_summary[total_income_000s]), 1000, 0),
            dim_financial_year[financial_year] = PriorYear
        ),
        BLANK()
    )

Income YoY Growth % =
VAR CY = [Total Income (£m)]
VAR PY = [Prior Year Income (£m)]
RETURN IF(NOT ISBLANK(PY), DIVIDE(CY - PY, PY, 0) * 100, BLANK())
```

### RAG Status

```dax
EBITDA RAG =
VAR Margin = [EBITDA Margin %]
RETURN
    SWITCH(
        TRUE(),
        ISBLANK(Margin), "Grey",
        Margin >= 5,     "Green",
        Margin >= 2,     "Amber",
        "Red"
    )

Surplus RAG =
VAR Margin = [Net Surplus Margin %]
RETURN
    SWITCH(
        TRUE(),
        ISBLANK(Margin), "Grey",
        Margin >= 0,     "Green",
        Margin >= -2,    "Amber",
        "Red"
    )
```

---

## 4. Report Pages

### Page 1 — Executive Summary

| Visual | Fields | Filters |
|--------|---------|---------|
| KPI Card | Total Income (£m) | Financial Year slicer |
| KPI Card | Operating Surplus (£m) | Trust Type slicer |
| KPI Card | EBITDA Margin % | Sector slicer |
| Bar chart | Income by sector (stacked) | — |
| Donut | Deficit vs Surplus count | — |
| Line chart | Total Income trend (3 years) | — |

### Page 2 — Income & Expenditure

| Visual | Fields |
|--------|---------|
| Waterfall | Income → Expenditure → Surplus bridge |
| Matrix | Trust / Year / Income / Expenditure / Surplus |
| Scatter | EBITDA Margin % vs Total Income (£m) |
| Bar | Top 10 trusts by income |

### Page 3 — Expenditure Detail

| Visual | Fields |
|--------|---------|
| Stacked bar | Pay / Non-pay / D&A by year |
| Bar | Pay % of income by sector |
| Column | Drugs cost by sector |
| Table | Cost per WTE by trust |

### Page 4 — Benchmarking

| Visual | Fields |
|--------|---------|
| Box plot / Bar | EBITDA margin distribution by sector |
| Scatter | Pay % vs EBITDA Margin |
| Table | Worst 20 trusts by net surplus margin |
| Table | Best 20 trusts by EBITDA margin |

### Page 5 — Workforce

| Visual | Fields |
|--------|---------|
| KPI Card | Total WTE |
| KPI Card | Total Staff Cost (£bn) |
| KPI Card | Avg Cost per WTE (£k) |
| Bar | WTE by sector |
| Line | Staff cost trend (3 years) |

---

## 5. NHS Colour Palette

```
NHS Blue:          #003087
NHS Dark Blue:     #002060
NHS Warm Yellow:   #FFB81C
NHS Bright Blue:   #0072CE
NHS Green:         #00843D
NHS Orange:        #ED8B00
NHS Red:           #DA291C
NHS Pale Grey:     #E8EDEE
```

---

## 6. Slicers (add to all pages)

- `dim_financial_year[financial_year]` — single-select, 3 years
- `dim_trust[sector]` — multi-select: Acute, Ambulance, Community, Mental Health, Specialist
- `dim_trust[trust_type]` — NHS Trust / Foundation Trust
- `dim_trust[region]` — NHS England regions
