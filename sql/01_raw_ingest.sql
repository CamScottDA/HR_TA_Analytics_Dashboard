-- =========================================================
-- Dimension Raw Ingest
-- =========================================================

-- dim_department_raw
CREATE OR REPLACE TEMP VIEW dim_department_raw_v AS
SELECT *
FROM read_files(
  '/Volumes/workspace/hr_analytics/portfolio_project/dim_department.csv',
  format => 'csv',
  header => true,
  inferSchema => true
);

CREATE OR REPLACE TABLE hr_analytics.dim_department_raw AS
SELECT *
FROM dim_department_raw_v;


-- dim_location_raw
CREATE OR REPLACE TEMP VIEW dim_location_raw_v AS
SELECT *
FROM read_files(
  '/Volumes/workspace/hr_analytics/portfolio_project/dim_location.csv',
  format => 'csv',
  header => true,
  inferSchema => true
);

CREATE OR REPLACE TABLE hr_analytics.dim_location_raw AS
SELECT *
FROM dim_location_raw_v;


-- dim_job_raw
CREATE OR REPLACE TEMP VIEW dim_job_raw_v AS
SELECT *
FROM read_files(
  '/Volumes/workspace/hr_analytics/portfolio_project/dim_job.csv',
  format => 'csv',
  header => true,
  inferSchema => true
);

CREATE OR REPLACE TABLE hr_analytics.dim_job_raw AS
SELECT *
FROM dim_job_raw_v;


-- =========================================================
-- Workforce Fact Raw Ingest
-- =========================================================

-- fct_employee_snapshot_monthly_raw
CREATE OR REPLACE TEMP VIEW fct_employee_snapshot_monthly_raw_v AS
SELECT *
FROM read_files(
  '/Volumes/workspace/hr_analytics/portfolio_project/fct_employee_snapshot_monthly.csv',
  format => 'csv',
  header => true,
  inferSchema => true
);

CREATE OR REPLACE TABLE hr_analytics.fct_employee_snapshot_monthly_raw AS
SELECT *
FROM fct_employee_snapshot_monthly_raw_v;


-- fct_employee_events_raw
CREATE OR REPLACE TEMP VIEW fct_employee_events_raw_v AS
SELECT *
FROM read_files(
  '/Volumes/workspace/hr_analytics/portfolio_project/fct_employee_events.csv',
  format => 'csv',
  header => true,
  inferSchema => true
);

CREATE OR REPLACE TABLE hr_analytics.fct_employee_events_raw AS
SELECT *
FROM fct_employee_events_raw_v;


-- =========================================================
-- Talent Acquisition Fact Raw Ingest
-- =========================================================

-- fct_requisitions_raw
CREATE OR REPLACE TEMP VIEW fct_requisitions_raw_v AS
SELECT *
FROM read_files(
  '/Volumes/workspace/hr_analytics/portfolio_project/fct_requisitions.csv',
  format => 'csv',
  header => true,
  inferSchema => true
);

CREATE OR REPLACE TABLE hr_analytics.fct_requisitions_raw AS
SELECT *
FROM fct_requisitions_raw_v;


-- fct_candidates_raw
CREATE OR REPLACE TEMP VIEW fct_candidates_raw_v AS
SELECT *
FROM read_files(
  '/Volumes/workspace/hr_analytics/portfolio_project/fct_candidates.csv',
  format => 'csv',
  header => true,
  inferSchema => true
);

CREATE OR REPLACE TABLE hr_analytics.fct_candidates_raw AS
SELECT *
FROM fct_candidates_raw_v;


-- fct_candidate_stage_events_raw
CREATE OR REPLACE TEMP VIEW fct_candidate_stage_events_raw_v AS
SELECT *
FROM read_files(
  '/Volumes/workspace/hr_analytics/portfolio_project/fct_candidate_stage_events.csv',
  format => 'csv',
  header => true,
  inferSchema => true
);

CREATE OR REPLACE TABLE hr_analytics.fct_candidate_stage_events_raw AS
SELECT *
FROM fct_candidate_stage_events_raw_v;
