-- =========================================================
-- Clean Dimensions
-- =========================================================

-- dim_department_clean
CREATE OR REPLACE VIEW hr_analytics.dim_department_clean AS
SELECT
  CAST(department_id AS INT) AS department_id,
  CASE
    WHEN upper(
      regexp_replace(
        replace(trim(CAST(department_name AS STRING)), '_', ' '),
        '\\s+',
        ' '
      )
    ) = 'HR' THEN 'HR'
    WHEN upper(
      regexp_replace(
        replace(trim(CAST(department_name AS STRING)), '_', ' '),
        '\\s+',
        ' '
      )
    ) = 'IT' THEN 'IT'
    ELSE initcap(
      regexp_replace(
        replace(trim(CAST(department_name AS STRING)), '_', ' '),
        '\\s+',
        ' '
      )
    )
  END AS department_name_clean,
  trim(org_group) AS org_group,
  nullif(trim(CAST(cost_center AS STRING)), '') AS cost_center_clean
FROM hr_analytics.dim_department_raw;


-- dim_location_clean
CREATE OR REPLACE VIEW hr_analytics.dim_location_clean AS
SELECT
  CAST(location_id AS INT) AS location_id,
  trim(
    regexp_replace(
      replace(location_name, '_', ' '),
      '\\s+',
      ' '
    )
  ) AS location_name_clean,
  trim(city) AS city,
  trim(state_province) AS state_province,
  CASE
    WHEN lower(trim(country)) IN ('us', 'usa', 'united states') THEN 'United States'
    WHEN lower(trim(country)) IN ('uk', 'united kingdom') THEN 'United Kingdom'
    WHEN lower(trim(country)) = 'de' THEN 'Germany'
    WHEN lower(trim(country)) = 'au' THEN 'Australia'
    WHEN lower(trim(country)) = 'ca' THEN 'Canada'
    ELSE initcap(trim(country))
  END AS country_clean,
  upper(trim(region)) AS region
FROM hr_analytics.dim_location_raw;


-- dim_job_clean
CREATE OR REPLACE VIEW hr_analytics.dim_job_clean AS
SELECT
  CAST(job_id AS INT) AS job_id,
  initcap(
    regexp_replace(
      replace(trim(job_title), '_', ' '),
      '\\s+',
      ' '
    )
  ) AS job_title_clean,
  trim(job_family) AS job_family,
  upper(trim(job_level)) AS job_level,
  CASE
    WHEN upper(trim(exempt_flag)) = 'Y' THEN 'Y'
    WHEN upper(trim(exempt_flag)) = 'N' THEN 'N'
    ELSE NULL
  END AS exempt_flag
FROM hr_analytics.dim_job_raw;


-- =========================================================
-- Clean Workforce Facts
-- =========================================================

-- fct_employee_snapshot_monthly_clean
CREATE OR REPLACE VIEW hr_analytics.fct_employee_snapshot_monthly_clean AS
SELECT
  to_date(trim(month_start), 'yyyy-MM-dd') AS month_start,
  trim(employee_id) AS employee_id,
  CAST(department_id AS INT) AS department_id,
  CAST(location_id AS INT) AS location_id,
  CAST(job_id AS INT) AS job_id,
  CASE
    WHEN lower(trim(employment_status)) = 'active' THEN 'Active'
    WHEN lower(trim(employment_status)) = 'terminated' THEN 'Terminated'
    ELSE NULL
  END AS employment_status_clean,
  CASE
    WHEN lower(trim(employment_status)) = 'active' THEN 1
    ELSE 0
  END AS is_active_flag,
  CAST(nullif(trim(CAST(fte AS STRING)), '') AS DOUBLE) AS fte,
  coalesce(
    to_date(nullif(nullif(trim(CAST(hire_date AS STRING)), 'NULL'), ''), 'yyyy-MM-dd'),
    to_date(nullif(nullif(trim(CAST(hire_date AS STRING)), 'NULL'), ''), 'M/d/yy'),
    to_date(nullif(nullif(trim(CAST(hire_date AS STRING)), 'NULL'), ''), 'MM/dd/yy')
  ) AS hire_date,
  coalesce(
    to_date(nullif(nullif(trim(CAST(termination_date AS STRING)), 'NULL'), ''), 'yyyy-MM-dd'),
    to_date(nullif(nullif(trim(CAST(termination_date AS STRING)), 'NULL'), ''), 'M/d/yy'),
    to_date(nullif(nullif(trim(CAST(termination_date AS STRING)), 'NULL'), ''), 'MM/dd/yy')
  ) AS termination_date,
  CASE
    WHEN lower(trim(termination_type)) = 'voluntary' THEN 'Voluntary'
    WHEN lower(trim(termination_type)) = 'involuntary' THEN 'Involuntary'
    WHEN lower(trim(termination_type)) = 'other' THEN 'Other'
    WHEN trim(coalesce(CAST(termination_type AS STRING), '')) = '' THEN NULL
    ELSE initcap(trim(CAST(termination_type AS STRING)))
  END AS termination_type_clean,
  nullif(trim(CAST(manager_id AS STRING)), '') AS manager_id,
  CAST(tenure_months AS INT) AS tenure_months,
  CASE
    WHEN CAST(tenure_months AS INT) BETWEEN 0 AND 6 THEN '0-6 months'
    WHEN CAST(tenure_months AS INT) BETWEEN 7 AND 12 THEN '7-12 months'
    WHEN CAST(tenure_months AS INT) BETWEEN 13 AND 24 THEN '13-24 months'
    WHEN CAST(tenure_months AS INT) BETWEEN 25 AND 36 THEN '25-36 months'
    WHEN CAST(tenure_months AS INT) >= 37 THEN '37+ months'
    ELSE 'Unknown'
  END AS tenure_band,
  CAST(nullif(regexp_replace(trim(CAST(base_salary_usd AS STRING)), ',', ''), '') AS DOUBLE) AS base_salary_usd
FROM hr_analytics.fct_employee_snapshot_monthly_raw;


-- fct_employee_events_clean
CREATE OR REPLACE VIEW hr_analytics.fct_employee_events_clean AS
SELECT
  trim(event_id) AS event_id,
  trim(employee_id) AS employee_id,
  coalesce(
    try_to_date(nullif(nullif(trim(CAST(event_date AS STRING)), 'NULL'), ''), 'yyyy-MM-dd'),
    try_to_date(nullif(nullif(trim(CAST(event_date AS STRING)), 'NULL'), ''), 'M/d/yy'),
    try_to_date(nullif(nullif(trim(CAST(event_date AS STRING)), 'NULL'), ''), 'MM/dd/yy')
  ) AS event_date,
  CAST(
    date_trunc(
      'month',
      coalesce(
        try_to_date(nullif(nullif(trim(CAST(event_date AS STRING)), 'NULL'), ''), 'yyyy-MM-dd'),
        try_to_date(nullif(nullif(trim(CAST(event_date AS STRING)), 'NULL'), ''), 'M/d/yy'),
        try_to_date(nullif(nullif(trim(CAST(event_date AS STRING)), 'NULL'), ''), 'MM/dd/yy')
      )
    ) AS DATE
  ) AS event_month,
  CASE
    WHEN lower(trim(event_type)) = 'hire' THEN 'Hire'
    WHEN lower(trim(event_type)) IN ('termination', 'term') THEN 'Termination'
    WHEN lower(trim(event_type)) = 'promotion' THEN 'Promotion'
    WHEN lower(trim(event_type)) = 'transfer' THEN 'Transfer'
    ELSE NULL
  END AS event_type_clean,
  CAST(nullif(trim(CAST(from_department_id AS STRING)), '') AS INT) AS from_department_id,
  CAST(nullif(trim(CAST(to_department_id AS STRING)), '') AS INT) AS to_department_id,
  CAST(nullif(trim(CAST(from_job_id AS STRING)), '') AS INT) AS from_job_id,
  CAST(nullif(trim(CAST(to_job_id AS STRING)), '') AS INT) AS to_job_id,
  CASE
    WHEN lower(trim(CAST(termination_type AS STRING))) = 'voluntary' THEN 'Voluntary'
    WHEN lower(trim(CAST(termination_type AS STRING))) = 'involuntary' THEN 'Involuntary'
    WHEN lower(trim(CAST(termination_type AS STRING))) = 'other' THEN 'Other'
    WHEN trim(coalesce(CAST(termination_type AS STRING), '')) = '' THEN NULL
    ELSE initcap(trim(CAST(termination_type AS STRING)))
  END AS termination_type_clean,
  nullif(trim(CAST(termination_reason AS STRING)), '') AS termination_reason
FROM hr_analytics.fct_employee_events_raw;


-- =========================================================
-- Clean Talent Acquisition Facts
-- =========================================================

-- fct_requisitions_clean
CREATE OR REPLACE VIEW hr_analytics.fct_requisitions_clean AS
WITH parsed AS (
  SELECT
    trim(req_id) AS req_id,
    CAST(department_id AS INT) AS department_id,
    CAST(location_id AS INT) AS location_id,
    CAST(job_id AS INT) AS job_id,
    coalesce(
      try_to_date(nullif(nullif(trim(CAST(opened_date AS STRING)), 'NULL'), ''), 'yyyy-MM-dd'),
      try_to_date(nullif(nullif(trim(CAST(opened_date AS STRING)), 'NULL'), ''), 'M/d/yy'),
      try_to_date(nullif(nullif(trim(CAST(opened_date AS STRING)), 'NULL'), ''), 'MM/dd/yy')
    ) AS opened_date_parsed,
    coalesce(
      try_to_date(nullif(nullif(trim(CAST(closed_date AS STRING)), 'NULL'), ''), 'yyyy-MM-dd'),
      try_to_date(nullif(nullif(trim(CAST(closed_date AS STRING)), 'NULL'), ''), 'M/d/yy'),
      try_to_date(nullif(nullif(trim(CAST(closed_date AS STRING)), 'NULL'), ''), 'MM/dd/yy')
    ) AS closed_date_parsed,
    coalesce(
      try_to_date(nullif(nullif(trim(CAST(target_start_date AS STRING)), 'NULL'), ''), 'yyyy-MM-dd'),
      try_to_date(nullif(nullif(trim(CAST(target_start_date AS STRING)), 'NULL'), ''), 'M/d/yy'),
      try_to_date(nullif(nullif(trim(CAST(target_start_date AS STRING)), 'NULL'), ''), 'MM/dd/yy')
    ) AS target_start_date,
    CASE
      WHEN lower(trim(CAST(req_status AS STRING))) = 'open' THEN 'Open'
      WHEN lower(trim(CAST(req_status AS STRING))) = 'closed' THEN 'Closed'
      WHEN lower(trim(CAST(req_status AS STRING))) = 'cancelled' THEN 'Cancelled'
      ELSE NULL
    END AS req_status_clean,
    CASE
      WHEN lower(trim(CAST(headcount_type AS STRING))) = 'backfill' THEN 'Backfill'
      WHEN lower(trim(CAST(headcount_type AS STRING))) = 'new' THEN 'New'
      ELSE NULL
    END AS headcount_type_clean,
    nullif(trim(CAST(hiring_manager_id AS STRING)), '') AS hiring_manager_id,
    nullif(trim(CAST(recruiter_id AS STRING)), '') AS recruiter_id
  FROM hr_analytics.fct_requisitions_raw
)

SELECT
  req_id,
  department_id,
  location_id,
  job_id,
  opened_date_parsed AS opened_date,
  CASE
    WHEN closed_date_parsed IS NOT NULL
         AND opened_date_parsed IS NOT NULL
         AND closed_date_parsed < opened_date_parsed THEN NULL
    ELSE closed_date_parsed
  END AS closed_date,
  req_status_clean,
  headcount_type_clean,
  target_start_date,
  hiring_manager_id,
  recruiter_id,
  CASE WHEN req_status_clean = 'Open' THEN 1 ELSE 0 END AS is_open_flag,
  CASE
    WHEN req_status_clean = 'Closed'
      AND opened_date_parsed IS NOT NULL
      AND closed_date_parsed IS NOT NULL
      AND closed_date_parsed >= opened_date_parsed
    THEN datediff(closed_date_parsed, opened_date_parsed)
    ELSE NULL
  END AS time_to_fill_days,
  CAST(date_trunc('month', opened_date_parsed) AS DATE) AS opened_month,
  CAST(
    date_trunc(
      'month',
      CASE
        WHEN closed_date_parsed IS NOT NULL
             AND opened_date_parsed IS NOT NULL
             AND closed_date_parsed < opened_date_parsed THEN NULL
        ELSE closed_date_parsed
      END
    ) AS DATE
  ) AS closed_month
FROM parsed;


-- fct_candidates_clean
CREATE OR REPLACE VIEW hr_analytics.fct_candidates_clean AS
WITH parsed AS (
  SELECT
    trim(candidate_app_id) AS candidate_app_id,
    trim(candidate_id) AS candidate_id,
    trim(req_id) AS req_id,
    coalesce(
      try_to_date(nullif(nullif(trim(CAST(application_date AS STRING)), 'NULL'), ''), 'yyyy-MM-dd'),
      try_to_date(nullif(nullif(trim(CAST(application_date AS STRING)), 'NULL'), ''), 'M/d/yy'),
      try_to_date(nullif(nullif(trim(CAST(application_date AS STRING)), 'NULL'), ''), 'MM/dd/yy')
    ) AS application_date,
    coalesce(
      try_to_date(nullif(nullif(trim(CAST(offer_date AS STRING)), 'NULL'), ''), 'yyyy-MM-dd'),
      try_to_date(nullif(nullif(trim(CAST(offer_date AS STRING)), 'NULL'), ''), 'M/d/yy'),
      try_to_date(nullif(nullif(trim(CAST(offer_date AS STRING)), 'NULL'), ''), 'MM/dd/yy')
    ) AS offer_date,
    coalesce(
      try_to_date(nullif(nullif(trim(CAST(accept_date AS STRING)), 'NULL'), ''), 'yyyy-MM-dd'),
      try_to_date(nullif(nullif(trim(CAST(accept_date AS STRING)), 'NULL'), ''), 'M/d/yy'),
      try_to_date(nullif(nullif(trim(CAST(accept_date AS STRING)), 'NULL'), ''), 'MM/dd/yy')
    ) AS accept_date,
    coalesce(
      try_to_date(nullif(nullif(trim(CAST(rejection_date AS STRING)), 'NULL'), ''), 'yyyy-MM-dd'),
      try_to_date(nullif(nullif(trim(CAST(rejection_date AS STRING)), 'NULL'), ''), 'M/d/yy'),
      try_to_date(nullif(nullif(trim(CAST(rejection_date AS STRING)), 'NULL'), ''), 'MM/dd/yy')
    ) AS rejection_date,
    CASE
      WHEN lower(trim(CAST(source AS STRING))) IN ('linkedin', 'linked in') THEN 'LinkedIn'
      WHEN lower(trim(CAST(source AS STRING))) IN ('indeed') THEN 'Indeed'
      WHEN lower(trim(CAST(source AS STRING))) IN ('referral', 'employee referral') THEN 'Employee Referral'
      WHEN lower(trim(CAST(source AS STRING))) IN ('company site', 'career site', 'company careers') THEN 'Company Site'
      WHEN lower(trim(CAST(source AS STRING))) IN ('agency', 'recruiting agency') THEN 'Agency'
      ELSE initcap(trim(CAST(source AS STRING)))
    END AS source_clean,
    CASE
      WHEN lower(trim(CAST(current_stage AS STRING))) IN ('application', 'applied') THEN 'Application'
      WHEN lower(trim(CAST(current_stage AS STRING))) IN ('phone_screen', 'phone screen', 'screen') THEN 'Phone Screen'
      WHEN lower(trim(CAST(current_stage AS STRING))) IN ('interview', 'onsite', 'panel interview') THEN 'Interview'
      WHEN lower(trim(CAST(current_stage AS STRING))) IN ('final interview', 'final_interview') THEN 'Final Interview'
      WHEN lower(trim(CAST(current_stage AS STRING))) = 'offer' THEN 'Offer'
      ELSE initcap(replace(trim(CAST(current_stage AS STRING)), '_', ' '))
    END AS current_stage_clean,
    CASE
      WHEN lower(trim(CAST(final_outcome AS STRING))) = 'hired' THEN 'Hired'
      WHEN lower(trim(CAST(final_outcome AS STRING))) = 'rejected' THEN 'Rejected'
      WHEN lower(trim(CAST(final_outcome AS STRING))) = 'withdrawn' THEN 'Withdrawn'
      WHEN lower(trim(CAST(final_outcome AS STRING))) IN ('in process', 'in_process', 'inprocess') THEN 'In Process'
      WHEN trim(coalesce(CAST(final_outcome AS STRING), '')) = '' THEN NULL
      ELSE initcap(replace(trim(CAST(final_outcome AS STRING)), '_', ' '))
    END AS final_outcome_clean
  FROM hr_analytics.fct_candidates_raw
)

SELECT
  candidate_app_id,
  candidate_id,
  req_id,
  application_date,
  source_clean,
  current_stage_clean,
  final_outcome_clean,
  offer_date,
  accept_date,
  rejection_date,
  CASE WHEN final_outcome_clean = 'Hired' THEN 1 ELSE 0 END AS is_hired_flag,
  CASE WHEN offer_date IS NOT NULL THEN 1 ELSE 0 END AS has_offer_flag,
  CASE WHEN accept_date IS NOT NULL THEN 1 ELSE 0 END AS has_accept_flag,
  CASE
    WHEN application_date IS NOT NULL
      AND offer_date IS NOT NULL
      AND offer_date >= application_date
    THEN datediff(offer_date, application_date)
    ELSE NULL
  END AS days_app_to_offer,
  CASE
    WHEN offer_date IS NOT NULL
      AND accept_date IS NOT NULL
      AND accept_date >= offer_date
    THEN datediff(accept_date, offer_date)
    ELSE NULL
  END AS days_offer_to_accept
FROM parsed;


-- fct_candidate_stage_events_clean
CREATE OR REPLACE VIEW hr_analytics.fct_candidate_stage_events_clean AS
WITH parsed AS (
  SELECT
    trim(stage_event_id) AS stage_event_id,
    trim(candidate_app_id) AS candidate_app_id,
    CASE
      WHEN lower(trim(CAST(stage_name AS STRING))) IN ('application', 'applied') THEN 'Application'
      WHEN lower(trim(CAST(stage_name AS STRING))) IN ('phone_screen', 'phone screen', 'screen') THEN 'Phone Screen'
      WHEN lower(trim(CAST(stage_name AS STRING))) IN ('hm interview', 'hiring manager interview') THEN 'Interview'
      WHEN lower(trim(CAST(stage_name AS STRING))) IN ('interview', 'onsite', 'panel interview') THEN 'Interview'
      WHEN lower(trim(CAST(stage_name AS STRING))) IN ('final interview', 'final_interview') THEN 'Final Interview'
      WHEN lower(trim(CAST(stage_name AS STRING))) IN ('offer', 'offer stage') THEN 'Offer'
      WHEN lower(trim(CAST(stage_name AS STRING))) = 'hired' THEN 'Hired'
      ELSE initcap(replace(trim(CAST(stage_name AS STRING)), '_', ' '))
    END AS stage_name_clean,
    coalesce(
      try_to_date(nullif(nullif(trim(CAST(stage_date AS STRING)), 'NULL'), ''), 'yyyy-MM-dd'),
      try_to_date(nullif(nullif(trim(CAST(stage_date AS STRING)), 'NULL'), ''), 'M/d/yy'),
      try_to_date(nullif(nullif(trim(CAST(stage_date AS STRING)), 'NULL'), ''), 'MM/dd/yy')
    ) AS stage_date,
    CASE
      WHEN lower(trim(CAST(stage_status AS STRING))) IN ('passed', 'pass') THEN 'Passed'
      WHEN lower(trim(CAST(stage_status AS STRING))) IN ('failed', 'fail', 'rejected') THEN 'Failed'
      WHEN lower(trim(CAST(stage_status AS STRING))) IN ('withdrew', 'withdrawn') THEN 'Withdrew'
      WHEN trim(coalesce(CAST(stage_status AS STRING), '')) = '' THEN NULL
      ELSE initcap(trim(CAST(stage_status AS STRING)))
    END AS stage_status_clean
  FROM hr_analytics.fct_candidate_stage_events_raw
)

SELECT
  stage_event_id,
  candidate_app_id,
  stage_name_clean,
  stage_date,
  stage_status_clean,
  CAST(date_trunc('month', stage_date) AS DATE) AS stage_month,
  CASE
    WHEN stage_name_clean = 'Application' THEN 1
    WHEN stage_name_clean = 'Phone Screen' THEN 2
    WHEN stage_name_clean = 'Interview' THEN 3
    WHEN stage_name_clean = 'Final Interview' THEN 4
    WHEN stage_name_clean = 'Offer' THEN 5
    WHEN stage_name_clean = 'Hired' THEN 6
    ELSE 99
  END AS stage_order
FROM parsed;
