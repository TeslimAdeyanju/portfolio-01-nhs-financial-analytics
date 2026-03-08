# KPI Definitions and Business Rules

All monetary values are in £000s unless stated. All KPIs use `data_type = 'ACTUAL'` unless noted.

---

## 1. EBITDA Margin %

**Definition:** Earnings Before Interest, Tax, Depreciation and Amortisation as a percentage of Total Income.
Measures underlying operational financial sustainability.

**Formula:**
```
EBITDA £000s = Total Income £000s - Total Pay £000s - Total Non-Pay £000s
               (excludes depreciation, interest, and impairment from non-pay)

EBITDA Margin % = EBITDA £000s / Total Income £000s × 100
```

**Filters:**
- Include: all income lines where `account_type = 'INCOME'`
- Include: all pay lines where `account_type = 'PAY'`
- Include: non-pay lines where `account_type = 'NON_PAY'` AND `subjective_code NOT IN ('DEPR', 'INT', 'IMP')`

**NHS benchmark:** A financially sustainable Trust targets ≥ 1% EBITDA Margin.
Trusts below 0% are in deficit and are subject to regulatory intervention.

**RAG thresholds:**
| Status | Range           |
|--------|-----------------|
| GREEN  | ≥ 2%            |
| AMBER  | 0% to < 2%      |
| RED    | < 0%            |

---

## 2. CIP Achievement %

**Definition:** Cost Improvement Programme (CIP) savings delivered as a percentage of the CIP target.
Measures delivery of the annual efficiency programme.

**Formula:**
```
CIP Achievement % = CIP Delivered £000s / CIP Target £000s × 100
```

**Source:** CIP data comes from a separate tracker (not in the main finance return).
Load from `data/raw/cip_tracker.xlsx` into `fct_cip_delivery`.

**NHS context:** NHS Trusts are typically set a CIP target of 2–5% of total expenditure annually.
Achievement below 80% is a significant risk flag.

**RAG thresholds:**
| Status | Range           |
|--------|-----------------|
| GREEN  | ≥ 100%          |
| AMBER  | 80% to < 100%   |
| RED    | < 80%           |

---

## 3. Pay as % of Income

**Definition:** Total pay costs as a percentage of total income. Measures workforce cost efficiency.

**Formula:**
```
Pay as % of Income = Total Pay £000s / Total Income £000s × 100
```

**Filters:**
- `account_type = 'PAY'` for pay
- `account_type = 'INCOME'` for income

**NHS benchmark:** Typically 60–70% for acute Trusts. Higher percentages indicate
higher labour intensity (common in mental health and community Trusts).

**RAG thresholds (acute Trust):**
| Status | Range           |
|--------|-----------------|
| GREEN  | < 65%           |
| AMBER  | 65% to < 70%    |
| RED    | ≥ 70%           |

---

## 4. Cost per WTE

**Definition:** Total staff costs divided by whole-time equivalent headcount.
Measures average cost per member of staff, used for benchmarking and run-rate analysis.

**Formula:**
```
Cost per WTE £000s = Total Pay £000s / Total WTE
```

**Sources:**
- Pay: `fct_income_expenditure` where `account_type = 'PAY'`
- WTE: `fct_workforce` — use `wte_actual` for substantive + bank only (exclude agency)

**Note:** Agency staff costs sit in `NON_PAY` not `PAY` in the finance return.
Always annotate when agency is included or excluded in the commentary.

**NHS benchmark:** Varies significantly by staff mix and geography. Use the
National Cost Collection national average as the comparator.

---

## 5. Budget Variance %

**Definition:** Difference between actual expenditure/income and budget, as a percentage of budget.
The primary measure of financial performance against plan.

**Formula:**
```
Variance £000s = Actual £000s - Budget £000s

Variance % = Variance £000s / ABS(Budget £000s) × 100
```

**Sign convention:**
- For income: positive variance = favourable (actual > budget)
- For expenditure: positive variance = adverse (actual > budget = overspend)
- Always display with explicit FAV / ADV label in reports to avoid confusion

**Cumulative YTD variance:** Use `SUM(actual_000s) - SUM(budget_000s)` across all periods
from M01 to the current period within the selected financial year.

**RAG thresholds:**
| Status | Income variance | Expenditure variance |
|--------|-----------------|----------------------|
| GREEN  | ≥ 0%            | ≤ 0%                 |
| AMBER  | -2% to 0%       | 0% to +2%            |
| RED    | < -2%           | > +2%                |

---

## 6. Capital Spend as % of Plan

**Definition:** Capital expenditure delivered as a percentage of the approved capital plan.
Measures delivery of the capital programme.

**Formula:**
```
Capital Spend % = Capital Actual £000s / Capital Plan £000s × 100
```

**Source:** `fct_income_expenditure` where `account_type = 'CAPITAL'`,
or `fct_estates` from ERIC data for annual reporting.

**NHS context:** NHS Trusts receive a capital resource limit from NHS England.
Underspend against plan may result in the limit being withdrawn in future years.
Overspend against the limit requires regulatory approval.

**RAG thresholds:**
| Status | Range           |
|--------|-----------------|
| GREEN  | 90%–110%        |
| AMBER  | 75%–90%         |
| RED    | < 75% or > 110% |

---

## 7. Agency as % of Total Pay (supplementary)

**Definition:** Agency staff costs as a percentage of total pay costs including agency.
Monitors use of expensive temporary staffing.

**Formula:**
```
Agency £000s = pay lines where subjective_code = 'AGENCY'
               (or non-pay lines coded as agency — check source mapping)

Agency % = Agency £000s / (Total Pay £000s + Agency £000s) × 100
```

**NHS target:** NHS England sets a ceiling for agency spend.
Trusts exceeding the ceiling are subject to additional oversight.
Target: agency < 3.5% of total pay bill.

---

## Aggregation Rules

- All KPIs are computed at **Trust level** by default
- All KPIs can be disaggregated to **Division** or **Directorate** where the source data supports it
- Do not aggregate across Trusts into a single total without a clear label ("Trust Group" or "Portfolio")
- Year-to-date KPIs always use cumulative sum from M01 to the current period within the financial year
- Do not mix `data_type = 'ACTUAL'` and `data_type = 'FORECAST'` in the same KPI row
