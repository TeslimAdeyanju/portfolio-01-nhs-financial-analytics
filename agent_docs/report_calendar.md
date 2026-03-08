# Report Calendar and Deadlines

## NHS Financial Year

| Period Label | Calendar Month | Quarter |
|--------------|----------------|---------|
| M01          | April          | Q1      |
| M02          | May            | Q1      |
| M03          | June           | Q1      |
| M04          | July           | Q2      |
| M05          | August         | Q2      |
| M06          | September      | Q2      |
| M07          | October        | Q3      |
| M08          | November       | Q3      |
| M09          | December       | Q3      |
| M10          | January        | Q4      |
| M11          | February       | Q4      |
| M12          | March          | Q4      |

Year-end close: **31 March**
Accounts submission to NHS England: **late June** (approximately 90 days after year-end)

---

## Monthly Reporting Cycle

Each NHS period closes approximately 10 working days after month-end.

| Milestone                              | Timing                          |
|----------------------------------------|---------------------------------|
| Period closes (data locked)            | ~10 working days after month-end|
| Finance data extracted from source     | Day 11                          |
| Python pipeline run (ingestion + clean)| Day 11–12                       |
| SQL views refreshed                    | Day 12                          |
| Power BI dataset refreshed             | Day 12                          |
| Draft monthly report produced          | Day 13                          |
| Finance Director sign-off              | Day 14                          |
| Board paper submitted                  | Day 15 (2 weeks before board)   |
| Trust Board meeting                    | Last Thursday of the month      |

---

## Quarterly Reporting Calendar (2023/24)

| Quarter | Period | Data covers           | Report due          | Audience              |
|---------|--------|-----------------------|---------------------|-----------------------|
| Q1      | M01–M03| Apr–Jun 2023          | Mid-July 2023       | Finance Committee     |
| Q2      | M01–M06| Apr–Sep 2023 (YTD)    | Mid-October 2023    | Finance Committee     |
| Q3      | M01–M09| Apr–Dec 2023 (YTD)    | Mid-January 2024    | Finance Committee     |
| Q4 / YE | M01–M12| Apr–Mar 2024 (full year)| Mid-April 2024    | Finance Committee + Board |

---

## Annual Accounts Timeline (2023/24)

| Milestone                              | Date                    |
|----------------------------------------|-------------------------|
| Year-end (M12 close)                   | 31 March 2024           |
| Draft accounts produced                | 30 April 2024           |
| External audit commences               | May 2024                |
| Audit findings issued                  | Early June 2024         |
| Accounts signed by Accountable Officer | Mid-June 2024           |
| Submission to NHS England              | Late June 2024          |
| Published on Trust website             | July 2024               |

---

## Regulatory Submissions (NHS England)

| Return                                | Frequency | Submitted by      | Deadline                   |
|---------------------------------------|-----------|-------------------|----------------------------|
| Monthly SitRep (finance position)     | Monthly   | Finance team      | Day 15 after period close  |
| Quarterly Provider Finance Return     | Quarterly | Finance team      | 3 weeks after quarter-end  |
| Consolidated Accounts                 | Annual    | Finance Director  | 90 days after year-end     |
| Capital return                        | Quarterly | Capital team      | 3 weeks after quarter-end  |
| CIP return                            | Monthly   | Finance team      | Day 15 after period close  |

---

## Project Data Refresh Schedule

For this analytics project, align data refresh with NHS reporting milestones:

| Data source               | Refresh frequency | Script                          |
|---------------------------|-------------------|---------------------------------|
| Provider Finance Return   | Annual (when published) | `python/ingestion/load_trust_returns.py` |
| Workforce Statistics      | Monthly           | `python/ingestion/load_workforce.py`     |
| Reference Costs           | Annual (when published) | `python/ingestion/load_reference_costs.py` |
| ERIC Estates              | Annual (when published) | `python/ingestion/load_eric.py`          |

NHS England typically publishes annual data 6–9 months after the financial year ends.
For 2023/24 data: expect publication in October–December 2024.

---

## Key NHS England Publication Dates (historical reference)

| Dataset                         | FY       | Published     |
|---------------------------------|----------|---------------|
| Provider Finance Return         | 2022/23  | November 2023 |
| Provider Finance Return         | 2021/22  | November 2022 |
| National Cost Collection        | 2022/23  | October 2023  |
| NHS Workforce Statistics        | Monthly  | ~6 weeks after reference month |
| ERIC                            | 2022/23  | February 2024 |
