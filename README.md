# HR + Talent Acquisition Analytics Dashboard (Portfolio Project)

## Project Overview
This project is a portfolio-ready HR + Talent Acquisition analytics build using a synthetic dataset representing a mid-sized company (~3,500 employees). The goal is to demonstrate end-to-end analytics workflow skills:

- multi-table dataset modeling (star-ish design)
- data cleaning and standardization
- metric-ready transformation logic
- relationship validation across files
- dashboard planning tied to stakeholder questions

This project is intentionally built with **realistic light data messiness** (mixed date formats, casing issues, label variants, blanks / `"NULL"` strings) to show practical cleaning and QA skills.

## Project Goal
Build a 2-page HR/TA dashboard that answers key stakeholder questions about:

1. Workforce growth/shrinkage trends
2. Attrition drivers (voluntary vs involuntary)
3. Hiring speed and bottlenecks
4. Source quality vs volume
5. Current funnel health and recruiting priorities

## Current Status
✅ Dataset design finalized  
✅ 9 CSV files generated and loaded  
✅ Raw tables created  
✅ Clean views created  
✅ Cross-table QA checks completed  
🔄 Dashboard build in progress (Workforce Health + TA Funnel pages)  
🔄 README insights/screenshots to be added after dashboard completion  

---

## Data Model (High Level)

### Dimensions
- `dim_date_month`
- `dim_department`
- `dim_location`
- `dim_job`

### Workforce Facts
- `fct_employee_snapshot_monthly`
- `fct_employee_events`

### Talent Acquisition Facts
- `fct_requisitions`
- `fct_candidates`
- `fct_candidate_stage_events`

### Relationship Design Principles
- Facts are segmented through shared dimensions (`department`, `location`, `job`, `month`)
- Avoid direct fact-to-fact joins in dashboard visuals unless pre-aggregated
- Candidate pipeline flows through:
  - `fct_candidates.req_id -> fct_requisitions.req_id`
  - `fct_candidate_stage_events.candidate_app_id -> fct_candidates.candidate_app_id`

---

## Data Cleaning & Standardization (Summary)

### Common issues intentionally included
- Mixed date formats (`yyyy-MM-dd`, `M/d/yy`, `MM/dd/yy`)
- Label casing inconsistencies (`Open/open/OPEN`)
- Stage/source variants (`LinkedIn`, `linked in`, etc.)
- Underscores and spacing issues in text fields
- Blank strings / `"NULL"` placeholders

### Cleaning approach
- Built a consistent pattern for each file:
  - `CSV -> temp view -> raw table -> clean view -> validation`
- Used `try_to_date(...)` + `coalesce(...)` for safe mixed-date parsing
- Standardized domains (status, outcomes, event types, stage names)
- Preserved important string IDs/fields where formatting matters (e.g., cost center)
- Added derived helper fields for dashboard use (examples below)

### Example derived helper fields
- Workforce:
  - `is_active_flag`
  - `tenure_band`
  - `event_month`
- TA:
  - `is_open_flag`
  - `time_to_fill_days`
  - `opened_month`, `closed_month`
  - `is_hired_flag`, `has_offer_flag`, `has_accept_flag`
  - `days_app_to_offer`, `days_offer_to_accept`
  - `stage_month`, `stage_order`

---

## Data Quality Validation (QA)
I ran both table-level and cross-table validation checks, including:

### Table-level QA
- Primary key / composite key uniqueness
- Null checks on key fields
- Category/domain standardization checks
- Date chronology checks (e.g., termination before hire)
- Trend readiness checks (month buckets populated)

### Cross-table QA
- Candidate -> Requisition key coverage
- Stage Event -> Candidate Application key coverage
- Fact -> Dimension key coverage (`department`, `location`, `job`)
- High-level funnel consistency checks (hired outcomes vs hired stage events)

### Data quality rule (documented)
Because this is synthetic data, a subset of requisitions had invalid chronology (`closed_date < opened_date`).  
I handled this in the **clean layer** by quarantining invalid `closed_date` values to `NULL` (without altering the raw table), which protects downstream time-to-fill metrics.

---

## Tools Used
- **Databricks SQL** (data ingestion, cleaning, validation)
- **CSV files** stored in a Databricks Volume
- *(Planned / optional)* Tableau or Databricks dashboards for visualization

---

## Repository Structure
```text
hr-ta-analytics-dashboard/
├── README.md
├── sql/
│   ├── 01_ingest_raw_tables.sql
│   ├── 02_create_clean_views.sql
│   ├── 03_validation_checks.sql
│   └── 04_dashboard_mart_views.sql   # (in progress)
├── docs/
│   ├── data_model_notes.md
│   ├── cleaning_checklist.md
│   └── dashboard_plan.md
├── screenshots/
│   └── (add dashboard screenshots here later)
└── sample_outputs/
    └── (optional)
hr-ta-analytics-dashboard/
├── README.md
├── sql/
│   ├── 01_ingest_raw_tables.sql
│   ├── 02_create_clean_views.sql
│   ├── 03_validation_checks.sql
│   └── 04_dashboard_mart_views.sql  # (in progress)
├── docs/
│   ├── data_model_notes.md
│   ├── cleaning_checklist.md
│   └── dashboard_plan.md
├── screenshots/
│   └── (dashboard is in progress)

