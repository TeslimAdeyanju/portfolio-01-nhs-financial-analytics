# NHS Trust Financial Analytics

End-to-end analytics portfolio using real NHS England public data.
Covers **206 NHS Trusts and Foundation Trusts** across **3 financial years (2021/22 – 2023/24)**.

---

## What this project demonstrates

| Skill | Implementation |
|-------|---------------|
| Data engineering | Python pipeline ingesting 6 NHS Excel files (6 × ~35MB) into MySQL |
| Star-schema design | `dim_trust`, `dim_financial_year`, `dim_worksheet`, `dim_subcode` → `fct_tac` |
| SQL analytics | Analytical views (I&E, expenditure, workforce, KPIs, scorecard) |
| Data validation | 10-query integrity checks with expected-value comments |
| Power BI | CSV export pipeline + DAX measures + 5-page dashboard spec |
| NHS domain knowledge | TAC subcodes, FReM conventions, sector benchmarks, ODS codes |

---

## Key findings from the data

| Metric | 2021/22 | 2022/23 | 2023/24 |
|--------|---------|---------|---------|
| Total NHS income | £110.3bn | £118.4bn | £129.2bn |
| Total NHS expenditure | £108.7bn | £118.2bn | £130.8bn |
| Operating surplus / (deficit) | +£1.6bn | +£148m | **−£1.6bn** |
| Trusts in deficit | 37 of 211 | 85 of 207 | **124 of 206** |
| Average EBITDA margin | 4.6% | 4.3% | 3.6% |

The sector moved from £1.6bn surplus in 2021/22 to a £1.6bn deficit in 2023/24 — a £3.2bn swing in two years — driven by pay pressures and inflation outpacing income growth.

---

## Data source

[NHS England Trust Accounts Consolidation (TAC)](https://www.england.nhs.uk/financial-accounting-reporting-systems/nhs-england-finance-returns-publications-guidance/trust-accounts-consolidation-tac/)

6 files downloaded: NHS Trusts and Foundation Trusts for 2021/22, 2022/23, and 2023/24.

---

## Project structure

```
├── agent_docs/
│   ├── data_dictionary.md      # TAC column and subcode reference
│   ├── kpi_definitions.md      # 7 KPI formulas with RAG thresholds
│   └── report_calendar.md      # NHS period table and reporting cycle
│
├── data/
│   ├── raw/                    # Source NHS Excel files (not committed)
│   └── processed/
│       └── powerbi_export/     # 8 CSV files ready for Power BI
│
├── python/
│   ├── ingestion/
│   │   └── load_tac_data.py    # Ingests all 6 TAC files → MySQL
│   └── reporting/
│       └── export_for_powerbi.py  # Exports MySQL views → CSVs
│
├── sql/
│   ├── schema/
│   │   └── create_tables_mysql.sql  # Full schema (staging + dims + fact + views)
│   ├── views/
│   │   ├── v_validation_checks.sql      # 10 data integrity checks
│   │   └── v_trust_annual_scorecard.sql # Wide analytical view
│   └── analysis/
│       └── sector_trend_analysis.sql    # 10 analysis queries for presentation
│
└── power_bi/
    └── setup_guide.md          # Model relationships, DAX measures, page specs
```

---

## Reproduce from scratch

### Prerequisites

- Python 3.11+ with `pandas`, `sqlalchemy`, `pymysql`, `openpyxl`
- MySQL 8.0+ (local)
- NHS TAC Excel files in `data/raw/`

### Steps

```bash
# 1. Create schema and seed dimensions
# Run sql/schema/create_tables_mysql.sql in DbVisualizer or MySQL Workbench

# 2. Ingest all 6 NHS files (~10 minutes total)
python python/ingestion/load_tac_data.py

# 3. Validate the load
# Run sql/views/v_validation_checks.sql (10 queries with expected values)

# 4. Export for Power BI
python python/reporting/export_for_powerbi.py
# Writes 8 CSVs to data/processed/powerbi_export/

# 5. Power BI
# Follow power_bi/setup_guide.md
```

---

## Database schema

Two MySQL databases:

- **`nhs_stg`** — staging layer (`stg_tac_raw`, `stg_provider_list`)
- **`nhs_finance`** — analytics layer:

| Table / View | Rows | Description |
|---|---|---|
| `dim_trust` | 215 | Provider master with ODS codes, sector, region |
| `fct_tac` | 2,179,740 | Raw fact: one row per org / year / subcode |
| `v_income_expenditure` | 624 | I&E per trust per year (from TAC02 SoCI) |
| `v_expenditure_breakdown` | 624 | Pay / non-pay / drugs split (from TAC08) |
| `v_workforce` | 624 | Staff costs and WTE (from TAC09) |
| `v_kpis` | 624 | Computed KPIs: EBITDA margin, pay %, cost per WTE |
| `v_trust_annual_scorecard` | 624 | Wide view combining all metrics + RAG flags |

---

## Power BI outputs (8 CSVs)

| File | Rows | Use |
|------|------|-----|
| `dim_trust.csv` | 215 | Slicer: sector, region, trust type |
| `dim_financial_year.csv` | 5 | Slicer: year |
| `kpis.csv` | 624 | KPI cards, scatter plots |
| `ie_summary.csv` | 624 | Waterfall, trend lines |
| `expenditure_breakdown.csv` | 624 | Pay vs non-pay breakdown |
| `workforce.csv` | 624 | WTE and staff cost cards |
| `income_detail.csv` | 9,144 | Income drilldown by line item |
| `expenditure_detail.csv` | 11,856 | Cost drilldown by line item |
| `sector_benchmarks.csv` | 30 | Aggregated sector summary |

---

## Known data notes

- WTE staff-group breakdown (nursing, medical etc.) has subcode ambiguity in the TAC format; total WTE (`STA0410`) is reliable
- 2021/22 files use `Organisation Name` (with space) and `Value number` columns — handled in the pipeline
- Each annual file contains Prior Year (PY) rows; the pipeline keeps Current Year (CY) only to avoid double-counting
