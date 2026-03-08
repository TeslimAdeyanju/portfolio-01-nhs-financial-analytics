# Python Layer — Pipeline Conventions

## Environment

- Python 3.11+
- Package manager: `pip` with `requirements.txt`
- Key libraries: `pandas`, `openpyxl`, `sqlalchemy`, `psycopg2`, `pydantic`, `pytest`

## Directory Layout

```
python/
├── ingestion/          # Parse and load raw NHS files into staging
├── transformation/     # Clean, type-cast, calculate derived fields
├── validation/         # Schema and business rule checks
├── reporting/          # Export outputs for Power BI or reports
├── utils/              # Shared helpers (db connection, logging, constants)
└── tests/              # pytest unit tests mirroring the above structure
```

## Coding Style

- Functions over classes unless state is genuinely needed
- One function = one responsibility; max ~40 lines per function
- All monetary arithmetic must preserve £000s denomination — add inline comment if it changes
- No magic numbers — define constants in `utils/constants.py`

## Pandas Style

- Always specify `dtype` when reading CSVs: `pd.read_csv(path, dtype={...})`
- Use `.pipe()` chaining for multi-step transformations
- Never use `.iterrows()` — use vectorised operations or `.apply()` only when necessary
- Column names: `snake_case` matching the SQL schema
- After any merge, assert the expected row count hasn't changed unexpectedly

## NHS File Ingestion Rules

### Provider Finance Excel Files
- NHS England finance returns use multi-row headers — skip the first N rows explicitly
- Sheet names vary by year; always look up sheet names dynamically: `pd.ExcelFile(path).sheet_names`
- Monetary columns arrive as strings with commas — strip and cast: `pd.to_numeric(col.str.replace(',', ''))`
- Suppress subtotal rows: drop rows where `account_code` is null or starts with `TOTAL`

### Workforce CSV Files
- ODS `org_code` column may contain trailing spaces — always `.str.strip()`
- WTE values may be `-` for suppressed data — replace with `NaN`, not 0

## Period Key Generation

```python
# period_key is YYYYMM integer
# NHS M01 = April, M12 = March
PERIOD_TO_MONTH = {f"M{i:02d}": (i + 3) if i <= 9 else (i - 9) for i in range(1, 13)}

def make_period_key(financial_year: str, period_label: str) -> int:
    """Convert '2023/24' + 'M01' -> 202304"""
    start_year = int(financial_year[:4])
    month = PERIOD_TO_MONTH[period_label]
    year = start_year if month >= 4 else start_year + 1
    return year * 100 + month
```

## Database Connection

Use `utils/db.py` — never hardcode credentials:

```python
import os
from sqlalchemy import create_engine

def get_engine():
    url = os.environ["NHS_DB_URL"]  # set in .env, never committed
    return create_engine(url)
```

## Output Paths

| Output type        | Path                                   |
|--------------------|----------------------------------------|
| Processed CSV      | `data/processed/<table_name>.csv`      |
| Validation report  | `data/processed/validation_report.csv` |
| Power BI export    | `data/processed/powerbi_export/`       |

## Validation Rules

Every ingestion run must check:
1. No null values in `org_code`, `period_key`, `account_type`
2. `actual_000s` is numeric (no text leakage)
3. Row count is within ±5% of the previous period's load
4. No duplicate `(org_code, period_key, account_code)` combinations

Validation failures write a row to `validation_report.csv` and raise a warning — they do NOT halt the pipeline unless severity is `CRITICAL`.

## Testing

- Test file for `ingestion/load_trust_returns.py` lives at `tests/test_load_trust_returns.py`
- Use `pytest` fixtures with small sample DataFrames — do not use real NHS files in tests
- Run: `pytest python/tests/ -v`

## Do Not

- Do not commit `.env` files or database URLs
- Do not load entire NHS files into memory if >500MB — use chunked reading
- Do not silently drop rows — log a warning with row count before and after any filter
- Do not use `print()` for pipeline logging — use Python `logging` module
