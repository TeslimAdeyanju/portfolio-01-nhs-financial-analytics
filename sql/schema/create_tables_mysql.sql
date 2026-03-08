-- NHS Trust Financial Analytics — MySQL Schema
-- Databases: nhs_stg (staging) and nhs_finance (analytics)
-- All monetary values in £000s unless stated otherwise
-- Source: NHS England TAC (Trust Accounts Consolidation) publications

-- ============================================================
-- DATABASES
-- ============================================================

CREATE DATABASE IF NOT EXISTS nhs_stg
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE DATABASE IF NOT EXISTS nhs_finance
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;


-- ============================================================
-- STAGING TABLES
-- ============================================================

USE nhs_stg;

DROP TABLE IF EXISTS stg_tac_raw;
CREATE TABLE stg_tac_raw (
    id                  BIGINT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    organisation_name   VARCHAR(300)    NOT NULL,
    worksheet_name      VARCHAR(50)     NOT NULL,
    table_id            SMALLINT        NOT NULL,
    main_code           VARCHAR(20)     NOT NULL,
    row_num             SMALLINT        NOT NULL,
    sub_code            VARCHAR(20)     NOT NULL,
    total               DECIMAL(14,0)   NOT NULL,        -- £000s
    source_file         VARCHAR(200)    NOT NULL,
    trust_type          VARCHAR(20)     NOT NULL,        -- NHS_TRUST | FOUNDATION_TRUST
    financial_year      CHAR(7)         NOT NULL,        -- e.g. 2023/24
    year_type           CHAR(2)         NOT NULL,        -- CY | PY
    load_ts             TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_stg_org_year  (organisation_name(100), financial_year),
    INDEX idx_stg_sub_code  (sub_code),
    INDEX idx_stg_year_type (financial_year, year_type)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS stg_provider_list;
CREATE TABLE stg_provider_list (
    id                  INT             NOT NULL AUTO_INCREMENT PRIMARY KEY,
    organisation_name   VARCHAR(300)    NOT NULL,
    org_code            CHAR(3)         NOT NULL,
    region              VARCHAR(100),
    sector              VARCHAR(50),
    comments            TEXT,
    source_file         VARCHAR(200)    NOT NULL,
    financial_year      CHAR(7)         NOT NULL,
    load_ts             TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_prov_org_code (org_code),
    INDEX idx_prov_name     (organisation_name(100))
) ENGINE=InnoDB;


-- ============================================================
-- DIMENSION TABLES
-- ============================================================

USE nhs_finance;

DROP TABLE IF EXISTS dim_trust;
CREATE TABLE dim_trust (
    org_code            CHAR(3)         NOT NULL PRIMARY KEY,
    organisation_name   VARCHAR(300)    NOT NULL,
    trust_type          VARCHAR(20)     NOT NULL,        -- NHS_TRUST | FOUNDATION_TRUST
    sector              VARCHAR(50),                     -- Acute | Mental Health | Community | Ambulance
    region              VARCHAR(100),
    is_foundation       TINYINT(1)      NOT NULL DEFAULT 0,
    first_year_seen     CHAR(7),
    last_year_seen      CHAR(7),
    updated_ts          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

DROP TABLE IF EXISTS dim_financial_year;
CREATE TABLE dim_financial_year (
    financial_year      CHAR(7)         NOT NULL PRIMARY KEY,  -- e.g. 2023/24
    start_date          DATE            NOT NULL,              -- 1 April
    end_date            DATE            NOT NULL,              -- 31 March
    year_label_short    CHAR(5)         NOT NULL,              -- e.g. 23/24
    is_complete         TINYINT(1)      NOT NULL DEFAULT 1
) ENGINE=InnoDB;

INSERT INTO dim_financial_year VALUES
    ('2019/20', '2019-04-01', '2020-03-31', '19/20', 1),
    ('2020/21', '2020-04-01', '2021-03-31', '20/21', 1),
    ('2021/22', '2021-04-01', '2022-03-31', '21/22', 1),
    ('2022/23', '2022-04-01', '2023-03-31', '22/23', 1),
    ('2023/24', '2023-04-01', '2024-03-31', '23/24', 1);

DROP TABLE IF EXISTS dim_worksheet;
CREATE TABLE dim_worksheet (
    worksheet_name      VARCHAR(50)     NOT NULL PRIMARY KEY,
    schedule_title      VARCHAR(200)    NOT NULL,
    category            VARCHAR(50)     NOT NULL,
    sub_code_prefix     VARCHAR(10)
) ENGINE=InnoDB;

INSERT INTO dim_worksheet VALUES
    ('TAC02 SoCI',           'Statement of Comprehensive Income',          'SUMMARY',        'SCI'),
    ('TAC03 SoFP',           'Statement of Financial Position',            'BALANCE_SHEET',  'SFP'),
    ('TAC04 SOCIE',          'Statement of Changes in Equity',             'EQUITY',         'SCE'),
    ('TAC05 SoCF',           'Statement of Cash Flows',                    'CASH_FLOW',      'SCF'),
    ('TAC06 Op Inc 1',       'Operating Income from Patient Care',         'INCOME',         'INC0'),
    ('TAC07 Op Inc 2',       'Other Operating Income',                     'INCOME',         'INC1'),
    ('TAC08 Op Exp',         'Operating Expenditure',                      'EXPENDITURE',    'EXP'),
    ('TAC09 Staff',          'Staff Costs and WTE Numbers',                'STAFF',          'STA'),
    ('TAC11 Finance & other','Finance Income, Expense and PDC',            'FINANCE',        'FIN'),
    ('TAC12 Impairment',     'Asset Impairments',                          'OTHER',          'IMP'),
    ('TAC13 Intangibles',    'Intangible Assets',                          'BALANCE_SHEET',  'INT'),
    ('TAC14 PPE',            'Property Plant and Equipment',               'BALANCE_SHEET',  'PPE'),
    ('TAC14A RoU Assets',    'Right-of-Use Assets (IFRS 16)',              'BALANCE_SHEET',  'ROU'),
    ('TAC18 Receivables',    'Receivables and Debtors',                    'BALANCE_SHEET',  'REC'),
    ('TAC19 CCE',            'Cash and Cash Equivalents',                  'BALANCE_SHEET',  'CCE'),
    ('TAC20 Payables',       'Payables and Creditors',                     'BALANCE_SHEET',  'PAY'),
    ('TAC22 Provisions',     'Provisions for Liabilities',                 'BALANCE_SHEET',  'PRV'),
    ('TAC28 Disclosures',    'Statutory Disclosures (NHS Trusts only)',     'OTHER',          'DIS'),
    ('TAC29 Losses+SP',      'Losses and Special Payments',                'OTHER',          'LSP');

DROP TABLE IF EXISTS dim_subcode;
CREATE TABLE dim_subcode (
    sub_code            VARCHAR(20)     NOT NULL PRIMARY KEY,
    worksheet_name      VARCHAR(50)     NOT NULL,
    description         VARCHAR(300)    NOT NULL,
    expected_sign       CHAR(3),
    unit                VARCHAR(10)     NOT NULL DEFAULT '£000',
    is_subtotal         TINYINT(1)      NOT NULL DEFAULT 0,
    analytics_category  VARCHAR(30),
    FOREIGN KEY (worksheet_name) REFERENCES dim_worksheet(worksheet_name)
) ENGINE=InnoDB;

INSERT INTO dim_subcode VALUES
    -- SoCI summary
    ('SCI0100A', 'TAC02 SoCI', 'Operating income from patient care activities',         '+',   '£000', 1, 'PATIENT_INCOME'),
    ('SCI0110A', 'TAC02 SoCI', 'Other operating income',                                '+',   '£000', 1, 'OTHER_INCOME'),
    ('SCI0125A', 'TAC02 SoCI', 'Operating expenses (total)',                            '-',   '£000', 1, 'TOTAL_EXPENDITURE'),
    ('SCI0140A', 'TAC02 SoCI', 'Operating surplus / (deficit)',                         '+/-', '£000', 1, 'OPERATING_SURPLUS'),
    ('SCI0150',  'TAC02 SoCI', 'Finance income',                                        '+',   '£000', 0, NULL),
    ('SCI0160',  'TAC02 SoCI', 'Finance expense',                                       '-',   '£000', 0, NULL),
    ('SCI0170',  'TAC02 SoCI', 'PDC dividend expense',                                  '-',   '£000', 0, NULL),
    ('SCI0240',  'TAC02 SoCI', 'Surplus / (deficit) for the year',                     '+/-', '£000', 1, 'NET_SURPLUS'),
    ('SOC0190',  'TAC02 SoCI', 'Total comprehensive income / (expense)',                '+/-', '£000', 1, NULL),
    -- Patient care income by nature
    ('INC0197',  'TAC06 Op Inc 1', 'API income - Variable (acute)',                     '+',   '£000', 0, 'PATIENT_INCOME'),
    ('INC0198',  'TAC06 Op Inc 1', 'API income - Fixed (acute)',                        '+',   '£000', 0, 'PATIENT_INCOME'),
    ('INC0200',  'TAC06 Op Inc 1', 'High cost drugs income from commissioners',         '+',   '£000', 0, 'PATIENT_INCOME'),
    ('INC0210',  'TAC06 Op Inc 1', 'Other NHS clinical income (acute)',                 '+',   '£000', 0, 'PATIENT_INCOME'),
    ('INC0231',  'TAC06 Op Inc 1', 'API income (mental health)',                        '+',   '£000', 0, 'PATIENT_INCOME'),
    ('INC0302',  'TAC06 Op Inc 1', 'API income (community)',                            '+',   '£000', 0, 'PATIENT_INCOME'),
    ('INC0330',  'TAC06 Op Inc 1', 'Private patient income',                            '+',   '£000', 0, 'PATIENT_INCOME'),
    ('INC0332',  'TAC06 Op Inc 1', 'Pay award central funding',                         '+',   '£000', 0, 'PATIENT_INCOME'),
    ('INC0340',  'TAC06 Op Inc 1', 'Other clinical income',                             '+',   '£000', 0, 'PATIENT_INCOME'),
    ('INC0350',  'TAC06 Op Inc 1', 'Total income from patient care activities',         '+',   '£000', 1, 'PATIENT_INCOME'),
    -- Patient care income by source
    ('INC1100',  'TAC06 Op Inc 1', 'Patient care income from NHS England',              '+',   '£000', 0, 'PATIENT_INCOME'),
    ('INC1115',  'TAC06 Op Inc 1', 'Patient care income from Integrated Care Boards',  '+',   '£000', 0, 'PATIENT_INCOME'),
    ('INC1140',  'TAC06 Op Inc 1', 'Patient care income from Local Authorities',        '+',   '£000', 0, 'PATIENT_INCOME'),
    ('INC1170',  'TAC06 Op Inc 1', 'Non-NHS: private patients',                         '+',   '£000', 0, 'PATIENT_INCOME'),
    ('INC1220',  'TAC06 Op Inc 1', 'Total income from patient care (by source)',        '+',   '£000', 1, 'PATIENT_INCOME'),
    -- Other operating income
    ('INC1230A', 'TAC07 Op Inc 2', 'Research and development income (IFRS 15)',         '+',   '£000', 0, 'OTHER_INCOME'),
    ('INC1240A', 'TAC07 Op Inc 2', 'Education and training income',                     '+',   '£000', 0, 'OTHER_INCOME'),
    ('INC1280A', 'TAC07 Op Inc 2', 'Non-patient care services to other bodies',         '+',   '£000', 0, 'OTHER_INCOME'),
    ('INC1360',  'TAC07 Op Inc 2', 'Total other operating income',                      '+',   '£000', 1, 'OTHER_INCOME'),
    ('INC1365',  'TAC07 Op Inc 2', 'Total operating income',                            '+',   '£000', 1, 'TOTAL_INCOME'),
    -- Operating expenditure
    ('EXP0100',  'TAC08 Op Exp', 'Purchase of healthcare from NHS bodies',              '+',   '£000', 0, 'NON_PAY'),
    ('EXP0110',  'TAC08 Op Exp', 'Purchase of healthcare from non-NHS bodies',          '+',   '£000', 0, 'NON_PAY'),
    ('EXP0130',  'TAC08 Op Exp', 'Staff and executive directors costs',                 '+',   '£000', 0, 'PAY'),
    ('EXP0140',  'TAC08 Op Exp', 'Non-executive directors costs',                       '+',   '£000', 0, 'PAY'),
    ('EXP0150',  'TAC08 Op Exp', 'Supplies and services - clinical',                    '+',   '£000', 0, 'NON_PAY'),
    ('EXP0160',  'TAC08 Op Exp', 'Supplies and services - general',                     '+',   '£000', 0, 'NON_PAY'),
    ('EXP0170',  'TAC08 Op Exp', 'Drugs costs',                                         '+',   '£000', 0, 'NON_PAY'),
    ('EXP0190',  'TAC08 Op Exp', 'Consultancy',                                         '+',   '£000', 0, 'NON_PAY'),
    ('EXP0200',  'TAC08 Op Exp', 'Establishment costs',                                 '+',   '£000', 0, 'NON_PAY'),
    ('EXP0210',  'TAC08 Op Exp', 'Premises - business rates',                           '+',   '£000', 0, 'NON_PAY'),
    ('EXP0220',  'TAC08 Op Exp', 'Premises - other',                                    '+',   '£000', 0, 'NON_PAY'),
    ('EXP0240',  'TAC08 Op Exp', 'Depreciation',                                        '+',   '£000', 0, 'NON_PAY_EXCL_EBITDA'),
    ('EXP0250',  'TAC08 Op Exp', 'Amortisation',                                        '+',   '£000', 0, 'NON_PAY_EXCL_EBITDA'),
    ('EXP0260',  'TAC08 Op Exp', 'Impairments net of reversals',                       '+/-', '£000', 0, 'NON_PAY_EXCL_EBITDA'),
    ('EXP0290A', 'TAC08 Op Exp', 'Clinical negligence premium (NHS Resolution)',        '+',   '£000', 0, 'NON_PAY'),
    ('EXP0300',  'TAC08 Op Exp', 'Research and development - staff costs',              '+',   '£000', 0, 'PAY'),
    ('EXP0320',  'TAC08 Op Exp', 'Education and training - staff costs',                '+',   '£000', 0, 'PAY'),
    ('EXP0350',  'TAC08 Op Exp', 'Redundancy costs - staff',                            '+',   '£000', 0, 'PAY'),
    ('EXP0370',  'TAC08 Op Exp', 'PFI / LIFT charges (on-SoFP)',                       '+',   '£000', 0, 'NON_PAY'),
    ('EXP0390',  'TAC08 Op Exp', 'Total operating expenditure',                         '+',   '£000', 1, 'TOTAL_EXPENDITURE'),
    -- Staff costs
    ('STA0220',  'TAC09 Staff', 'Total gross staff costs',                              '+',   '£000', 1, 'PAY'),
    ('STA0250',  'TAC09 Staff', 'Total staff costs (net of recoveries)',                '+',   '£000', 1, 'PAY'),
    -- WTE numbers
    ('STA0310',  'TAC09 Staff', 'Medical and dental WTE',                               '+',   'No.',  0, 'STAFF_WTE'),
    ('STA0330',  'TAC09 Staff', 'Administration and estates WTE',                       '+',   'No.',  0, 'STAFF_WTE'),
    ('STA0340',  'TAC09 Staff', 'Healthcare assistants WTE',                            '+',   'No.',  0, 'STAFF_WTE'),
    ('STA0350',  'TAC09 Staff', 'Nursing, midwifery and health visiting WTE',           '+',   'No.',  0, 'STAFF_WTE'),
    ('STA0370',  'TAC09 Staff', 'Scientific, therapeutic and technical WTE',            '+',   'No.',  0, 'STAFF_WTE'),
    ('STA0410',  'TAC09 Staff', 'Total average WTE',                                    '+',   'No.',  1, 'STAFF_WTE'),
    ('STA0530',  'TAC09 Staff', 'Total days lost to sickness',                          '+',   'No.',  0, 'STAFF_WTE'),
    ('STA0550',  'TAC09 Staff', 'Average working days lost per WTE',                    '+',   'No.',  0, 'STAFF_WTE');


-- ============================================================
-- FACT TABLE
-- ============================================================

DROP TABLE IF EXISTS fct_tac;
CREATE TABLE fct_tac (
    tac_id              BIGINT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    org_code            CHAR(3)         NOT NULL,
    financial_year      CHAR(7)         NOT NULL,
    worksheet_name      VARCHAR(50)     NOT NULL,
    table_id            SMALLINT        NOT NULL,
    main_code           VARCHAR(20)     NOT NULL,
    sub_code            VARCHAR(20)     NOT NULL,
    total_000s          DECIMAL(14,0)   NOT NULL,
    trust_type          VARCHAR(20)     NOT NULL,
    source_file         VARCHAR(200)    NOT NULL,
    load_ts             TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_tac (org_code, financial_year, main_code, sub_code),
    INDEX idx_fct_org_year  (org_code, financial_year),
    INDEX idx_fct_sub_code  (sub_code),
    INDEX idx_fct_worksheet (worksheet_name),
    INDEX idx_fct_year      (financial_year),
    FOREIGN KEY (org_code)       REFERENCES dim_trust(org_code),
    FOREIGN KEY (financial_year) REFERENCES dim_financial_year(financial_year),
    FOREIGN KEY (worksheet_name) REFERENCES dim_worksheet(worksheet_name)
) ENGINE=InnoDB;


-- ============================================================
-- ANALYTICAL VIEWS
-- ============================================================

-- v_income_expenditure: top-level I&E from TAC02 SoCI
DROP VIEW IF EXISTS v_income_expenditure;
CREATE VIEW v_income_expenditure AS
SELECT
    t.org_code,
    t.organisation_name,
    t.sector,
    t.region,
    t.trust_type,
    f.financial_year,
    MAX(CASE WHEN f.sub_code = 'SCI0100A' THEN f.total_000s END) AS patient_care_income_000s,
    MAX(CASE WHEN f.sub_code = 'SCI0110A' THEN f.total_000s END) AS other_income_000s,
    COALESCE(MAX(CASE WHEN f.sub_code = 'SCI0100A' THEN f.total_000s END), 0)
        + COALESCE(MAX(CASE WHEN f.sub_code = 'SCI0110A' THEN f.total_000s END), 0)
        AS total_income_000s,
    ABS(COALESCE(MAX(CASE WHEN f.sub_code = 'SCI0125A' THEN f.total_000s END), 0)) AS total_expenditure_000s,
    MAX(CASE WHEN f.sub_code = 'SCI0140A' THEN f.total_000s END) AS operating_surplus_000s,
    MAX(CASE WHEN f.sub_code = 'SCI0240'  THEN f.total_000s END) AS net_surplus_000s
FROM fct_tac f
JOIN dim_trust t ON f.org_code = t.org_code
WHERE f.worksheet_name = 'TAC02 SoCI'
GROUP BY t.org_code, t.organisation_name, t.sector, t.region, t.trust_type, f.financial_year;

-- v_expenditure_breakdown: operating expenditure by category
DROP VIEW IF EXISTS v_expenditure_breakdown;
CREATE VIEW v_expenditure_breakdown AS
SELECT
    t.org_code,
    t.organisation_name,
    t.sector,
    t.region,
    t.trust_type,
    f.financial_year,
    SUM(CASE WHEN sc.analytics_category = 'PAY'                 THEN f.total_000s ELSE 0 END) AS pay_000s,
    SUM(CASE WHEN sc.analytics_category = 'NON_PAY'             THEN f.total_000s ELSE 0 END) AS non_pay_000s,
    SUM(CASE WHEN sc.analytics_category = 'NON_PAY_EXCL_EBITDA' THEN f.total_000s ELSE 0 END) AS depreciation_amort_000s,
    MAX(CASE WHEN f.sub_code = 'EXP0170' THEN f.total_000s END) AS drugs_cost_000s,
    MAX(CASE WHEN f.sub_code = 'EXP0130' THEN f.total_000s END) AS staff_cost_000s,
    MAX(CASE WHEN f.sub_code = 'EXP0390' THEN f.total_000s END) AS total_expenditure_000s
FROM fct_tac f
JOIN dim_trust t    ON f.org_code = t.org_code
JOIN dim_subcode sc ON f.sub_code = sc.sub_code
WHERE f.worksheet_name = 'TAC08 Op Exp'
GROUP BY t.org_code, t.organisation_name, t.sector, t.region, t.trust_type, f.financial_year;

-- v_workforce: staff costs and WTE from TAC09
DROP VIEW IF EXISTS v_workforce;
CREATE VIEW v_workforce AS
SELECT
    t.org_code,
    t.organisation_name,
    t.sector,
    t.region,
    t.trust_type,
    f.financial_year,
    MAX(CASE WHEN f.sub_code = 'STA0250' THEN f.total_000s END) AS total_staff_cost_000s,
    MAX(CASE WHEN f.sub_code = 'STA0220' THEN f.total_000s END) AS gross_staff_cost_000s,
    MAX(CASE WHEN f.sub_code = 'STA0410' THEN f.total_000s END) AS total_wte,
    MAX(CASE WHEN f.sub_code = 'STA0310' THEN f.total_000s END) AS medical_wte,
    MAX(CASE WHEN f.sub_code = 'STA0350' THEN f.total_000s END) AS nursing_wte,
    MAX(CASE WHEN f.sub_code = 'STA0330' THEN f.total_000s END) AS admin_estates_wte,
    MAX(CASE WHEN f.sub_code = 'STA0370' THEN f.total_000s END) AS scientific_tech_wte,
    MAX(CASE WHEN f.sub_code = 'STA0550' THEN f.total_000s END) AS avg_days_lost_per_wte
FROM fct_tac f
JOIN dim_trust t ON f.org_code = t.org_code
WHERE f.worksheet_name = 'TAC09 Staff'
GROUP BY t.org_code, t.organisation_name, t.sector, t.region, t.trust_type, f.financial_year;

-- v_kpis: computed KPIs
DROP VIEW IF EXISTS v_kpis;
CREATE VIEW v_kpis AS
SELECT
    ie.org_code,
    ie.organisation_name,
    ie.sector,
    ie.region,
    ie.trust_type,
    ie.financial_year,
    ie.total_income_000s,
    ie.total_expenditure_000s,
    ie.operating_surplus_000s,
    ie.net_surplus_000s,
    ex.pay_000s,
    ex.staff_cost_000s,
    ex.drugs_cost_000s,
    ex.depreciation_amort_000s,
    wf.total_wte,
    wf.medical_wte,
    wf.nursing_wte,
    wf.avg_days_lost_per_wte,
    -- EBITDA
    ie.operating_surplus_000s + COALESCE(ex.depreciation_amort_000s, 0) AS ebitda_000s,
    -- EBITDA Margin %
    ROUND(
        (ie.operating_surplus_000s + COALESCE(ex.depreciation_amort_000s, 0))
        / NULLIF(ie.total_income_000s, 0) * 100, 1
    ) AS ebitda_margin_pct,
    -- Pay as % of income
    ROUND(ex.pay_000s / NULLIF(ie.total_income_000s, 0) * 100, 1) AS pay_pct_income,
    -- Cost per WTE (£000s per WTE)
    ROUND(ex.staff_cost_000s / NULLIF(wf.total_wte, 0), 1) AS cost_per_wte_000s,
    -- Net surplus margin %
    ROUND(ie.net_surplus_000s / NULLIF(ie.total_income_000s, 0) * 100, 1) AS net_surplus_margin_pct
FROM v_income_expenditure ie
LEFT JOIN v_expenditure_breakdown ex
    ON ie.org_code = ex.org_code AND ie.financial_year = ex.financial_year
LEFT JOIN v_workforce wf
    ON ie.org_code = wf.org_code AND ie.financial_year = wf.financial_year;
