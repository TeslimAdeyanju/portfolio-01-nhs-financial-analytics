# Reports Layer — IFRS Formatting and Narrative Standards

## Report Types

| Report                   | Frequency | Audience              | Format   |
|--------------------------|-----------|-----------------------|----------|
| Monthly Finance Report   | Monthly   | Trust Board           | Markdown / Word |
| Quarterly Accounts Pack  | Quarterly | Finance Committee     | Markdown / PDF  |
| Annual Accounts Summary  | Annual    | Public / Regulator    | Markdown / PDF  |

## IFRS / FReM Compliance

All reports follow:
- **NHS Financial Reporting Manual (FReM)** — governs presentation for NHS bodies
- **IFRS 16** — lease accounting (right-of-use assets in capital section)
- **IAS 36** — impairment (flag any impairment indicators in estates section)

## Narrative Standards

### Structure of every monthly report

```
1. Executive Summary          (max 200 words)
2. Income and Expenditure     (actuals vs budget, key variances explained)
3. Workforce and Pay          (WTE run rate, agency spend commentary)
4. Capital Programme          (spend vs plan, scheme-level commentary)
5. Cash and Balance Sheet     (cash position, aged debtors)
6. Risks and Mitigations      (top 3 financial risks this period)
7. Appendices                 (detailed tables)
```

### Tone and language

- Write in plain English suitable for a non-finance board member
- Lead every section with the bottom line: state the position, then explain it
- Use active voice: "The Trust overspent by £1.2m" not "An overspend of £1.2m was incurred"
- Avoid abbreviations without first defining them
- Do not use "circa", "approximately", or hedging language — state the number

### Number formatting in narrative

| Amount         | Format              | Example              |
|----------------|---------------------|----------------------|
| < £1m          | £000s               | £342,000             |
| £1m – £100m    | £m to 1 decimal     | £4.2m                |
| > £100m        | £m to nearest whole | £312m                |

- Percentages: always 1 decimal place — `4.3%` not `4%` or `4.32%`
- Never use £000s notation in narrative text — spell it out as thousands or millions

### Variance commentary rules

- Always state: actual, budget, variance (£ and %), and reason
- For overspends: explain root cause and mitigation action
- For underspends: explain whether structural or timing
- Template: `"[Cost centre] reported an overspend of £Xm (Y%) against budget, driven by [reason]. [Mitigation action] is expected to recover £Zm by year-end."`

## File Naming

```
reports/outputs/YYYY_QN_Finance_Report.md        # Quarterly
reports/outputs/YYYY_MM_Monthly_Finance_Report.md # Monthly
reports/outputs/YYYY_Annual_Accounts_Summary.md   # Annual
```

## Templates

- Base template: `reports/templates/monthly_finance_report.md`
- Do not modify the template — copy it to `outputs/` and populate it

## Do Not

- Do not include patient-identifiable information in any report
- Do not present forecast as actuals — label clearly: `[FORECAST]` or `[ACTUAL]`
- Do not round to nearest £m when the variance is less than £1m — precision matters
- Do not use tables wider than 100 characters in Markdown (breaks PDF rendering)
