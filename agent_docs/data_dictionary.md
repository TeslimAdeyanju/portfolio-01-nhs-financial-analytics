# Data Dictionary

## Source Files (downloaded to data/raw/)

| File | Size | Trusts | Years covered |
|------|------|--------|---------------|
| `TAC_NHS_trusts_2021-22.xlsx` | 16MB | 66 NHS Trusts | 2021/22 (CY) + 2020/21 (PY) |
| `TAC_NHS_foundation_trusts_2021-22.xlsx` | 33MB | 140 Foundation Trusts | 2021/22 (CY) + 2020/21 (PY) |
| `TAC_NHS_trusts_2022-23.xlsx` | 20MB | 66 NHS Trusts | 2022/23 (CY) + 2021/22 (PY) |
| `TAC_NHS_foundation_trusts_2022-23.xlsx` | 36MB | 140 Foundation Trusts | 2022/23 (CY) + 2021/22 (PY) |
| `TAC_NHS_trusts_2023-24.xlsx` | 18MB | 66 NHS Trusts | 2023/24 (CY) + 2022/23 (PY) |
| `TAC_NHS_foundation_trusts_2023-24.xlsx` | 38MB | 140 Foundation Trusts | 2023/24 (CY) + 2022/23 (PY) |
| `TAC_illustrative_2023-24.xlsx` | 299KB | Reference only | Schema/subcode guide |

Total providers: **206** (66 NHS Trusts + 140 Foundation Trusts)
Total data rows per file: ~481,000 (trusts) / ~1.1M (foundation trusts)

---

## Raw Data Structure

Every data file contains a sheet called **"All data"** with exactly **7 columns**:

| Column | Type | Description | Example |
|--------|------|-------------|---------|
| `OrganisationName` | string | Full legal name of the Trust | `Barts Health NHS Trust` |
| `WorkSheetName` | string | TAC schedule name | `TAC02 SoCI` |
| `TableID` | integer | Table number within the sheet | `1` |
| `MainCode` | string | Column identifier (sheet + CY/PY + table) | `A02CY01` |
| `RowNumber` | integer | Row position in original form | `12` |
| `SubCode` | string | Unique line item identifier | `SCI0100A` |
| `Total` | integer | Value in **£000s** | `350689` |

### MainCode convention

Format: `A{sheet_number}{CY|PY}{table_number}`

| Part | Meaning | Example |
|------|---------|---------|
| `A02` | TAC sheet number (02 = SoCI) | A02, A06, A08, A09 |
| `CY` | Current Year data | 2023/24 in the 2023/24 file |
| `PY` | Prior Year data | 2022/23 in the 2023/24 file |
| `01` | Table ID within sheet | 01, 02, 03… |

**Important:** Each annual file contains BOTH current year (CY) and prior year (PY) rows.
When building a multi-year series, use CY rows only to avoid double-counting.

### "List of Providers" sheet

| Column | Description | Example |
|--------|-------------|---------|
| `Full name of Provider` | Trust name (matches OrganisationName) | `Barts Health NHS Trust` |
| `NHS code` | 3-character ODS code | `R1H` |
| `Region` | NHS England region | `London` |
| `Sector` | Trust type | `Acute`, `Mental Health`, `Community`, `Ambulance` |
| `Comments` | Exclusion notes if applicable | null or exclusion reason |

---

## TAC Worksheet Schedule Reference

| WorkSheetName | Content | Key SubCode prefix |
|---------------|---------|-------------------|
| `TAC02 SoCI` | Statement of Comprehensive Income (summary P&L) | SCI, SOC |
| `TAC03 SoFP` | Statement of Financial Position (balance sheet) | SFP |
| `TAC04 SOCIE` | Statement of Changes in Equity | SCE |
| `TAC05 SoCF` | Statement of Cash Flows | SCF |
| `TAC06 Op Inc 1` | Operating income from patient care (by nature + source) | INC0xxx |
| `TAC07 Op Inc 2` | Other operating income | INC1xxx |
| `TAC08 Op Exp` | Operating expenditure (detailed breakdown) | EXP |
| `TAC09 Staff` | Staff costs (pay) and WTE numbers | STA |
| `TAC11 Finance & other` | Finance income, finance expense, PDC | FIN |
| `TAC12 Impairment` | Asset impairments | IMP |
| `TAC13 Intangibles` | Intangible assets | INT |
| `TAC14 PPE` | Property, Plant and Equipment | PPE |
| `TAC14A RoU Assets` | Right-of-use assets (IFRS 16 leases) | ROU |
| `TAC18 Receivables` | Debtors and receivables | REC |
| `TAC19 CCE` | Cash and cash equivalents | CCE |
| `TAC20 Payables` | Creditors and payables | PAY |
| `TAC22 Provisions` | Provisions for liabilities | PRV |
| `TAC28 Disclosures` | Statutory disclosures (NHS trusts only) | DIS |
| `TAC29 Losses+SP` | Losses and special payments | LSP |

---

## Key SubCodes for Analytics

### TAC02 SoCI — Summary Income & Expenditure

| SubCode | Description | Sign |
|---------|-------------|------|
| `SCI0100A` | Operating income from patient care activities | + |
| `SCI0110A` | Other operating income | + |
| `SCI0125A` | Operating expenses (total, shown negative) | − |
| `SCI0140A` | **Operating surplus / (deficit)** | +/− |
| `SCI0150` | Finance income | + |
| `SCI0160` | Finance expense | − |
| `SCI0170` | PDC dividend expense | − |
| `SCI0180` | Net finance costs | +/− |
| `SCI0190A` | Other gains / (losses) | +/− |
| `SCI0240` | **Surplus / (deficit) for the year** | +/− |
| `SOC0190` | **Total comprehensive income / (expense)** | +/− |

### TAC06 Op Inc 1 — Patient Care Income (by nature)

| SubCode | Description |
|---------|-------------|
| `INC0197` | API income — Variable (acute, activity-based) |
| `INC0198` | API income — Fixed (acute, non-activity) |
| `INC0200` | High cost drugs income from commissioners |
| `INC0210` | Other NHS clinical income (acute) |
| `INC0231` | API income (mental health) |
| `INC0302` | API income (community) |
| `INC0330` | Private patient income |
| `INC0332` | Pay award central funding |
| `INC0340` | Other clinical income |
| `INC0350` | **Total income from patient care activities** |

### TAC06 Op Inc 1 — Patient Care Income (by source, Table 2)

| SubCode | Description |
|---------|-------------|
| `INC1100` | NHS England |
| `INC1115` | Integrated Care Boards |
| `INC1140` | Local authorities |
| `INC1170` | Non-NHS: private patients |
| `INC1180` | Non-NHS: overseas patients |
| `INC1220` | **Total income from patient care (by source)** |

### TAC07 Op Inc 2 — Other Operating Income

| SubCode | Description |
|---------|-------------|
| `INC1230A` | Research and development (IFRS 15) |
| `INC1240A` | Education and training |
| `INC1280A` | Non-patient care services to other bodies |
| `INC1320` | Income in respect of employee benefits |
| `INC1360` | **Total other operating income** |
| `INC1365` | **Total operating income** |

### TAC08 Op Exp — Operating Expenditure

| SubCode | Description | Category |
|---------|-------------|----------|
| `EXP0100` | Purchase of healthcare from NHS bodies | Non-pay |
| `EXP0110` | Purchase of healthcare from non-NHS bodies | Non-pay |
| `EXP0130` | **Staff and executive directors costs** | Pay |
| `EXP0140` | Non-executive directors | Pay |
| `EXP0150` | Supplies and services — clinical | Non-pay |
| `EXP0160` | Supplies and services — general | Non-pay |
| `EXP0170` | Drugs costs | Non-pay |
| `EXP0190` | Consultancy | Non-pay |
| `EXP0200` | Establishment | Non-pay |
| `EXP0210` | Premises — business rates | Non-pay |
| `EXP0220` | Premises — other | Non-pay |
| `EXP0240` | **Depreciation** | Non-pay (excl. from EBITDA) |
| `EXP0250` | **Amortisation** | Non-pay (excl. from EBITDA) |
| `EXP0260` | Impairments net of reversals | Non-pay (excl. from EBITDA) |
| `EXP0290A` | Clinical negligence premium (NHS Resolution) | Non-pay |
| `EXP0300` | Research and development — staff costs | Pay |
| `EXP0320` | Education and training — staff costs | Pay |
| `EXP0350` | Redundancy costs — staff | Pay |
| `EXP0370` | PFI / LIFT on-SoFP charges | Non-pay |
| `EXP0390` | **Total operating expenditure** | |

### TAC09 Staff — Pay Costs and WTE Numbers

**Table: Note 5.2 Employee Expenses (MainCode A09CY01 = Total, A09CY01P = Permanent, A09CY01O = Other)**

| SubCode | Description | Unit |
|---------|-------------|------|
| `STA0100` | Salaries and wages | £000 |
| `STA0110` | Social security costs | £000 |
| `STA0120` | Apprenticeship levy | £000 |
| `STA0130` | Pension cost — employer contributions | £000 |
| `STA0150` | Pension cost — other | £000 |
| `STA0190` | Temporary staff — external bank | £000 |
| `STA0200` | Temporary staff — agency/contract | £000 |
| `STA0220` | **Total gross staff costs** | £000 |
| `STA0250` | **Total staff costs** | £000 |

**Table: Note 5.3 Average WTE numbers (MainCode A09CY01)**

| SubCode | Description | Unit |
|---------|-------------|------|
| `STA0310` | Medical and dental (WTE) | No. |
| `STA0320` | Ambulance staff (WTE) | No. |
| `STA0330` | Administration and estates (WTE) | No. |
| `STA0340` | Healthcare assistants and other support (WTE) | No. |
| `STA0350` | Nursing, midwifery and health visiting (WTE) | No. |
| `STA0370` | Scientific, therapeutic and technical (WTE) | No. |
| `STA0390` | Social care staff (WTE) | No. |
| `STA0400` | Other (WTE) | No. |
| `STA0410` | **Total average WTE** | No. |

---

## Data Quality Notes

- **Excluded providers:** Some trusts are excluded per-file where board adoption or audit opinion was outstanding at publication. Check the "List of Providers" Comments column.
- **Prior Year rows:** Each file contains PY rows (MainCode contains `PY`). Use only CY rows to avoid duplication when combining files.
- **Zero values:** Zero is a valid submission — do not treat as null.
- **Negative values:** Expenditure lines are stored as positive numbers in the raw data; the SoCI uses sign convention (+income, −expenditure). Always check the `Expected sign` column in the illustrative file.
- **NHS Charitable Funds:** Data includes any locally consolidated NHS charitable funds. SubCodes prefixed `OPX`, `OPO`, `OPP` relate to charitable fund activity.
- **Foundation Trust vs NHS Trust files:** Identical column structure. TAC28 (Disclosures) tables 6–8 exist only in NHS Trust files, not Foundation Trust files.
