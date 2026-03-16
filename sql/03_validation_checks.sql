-- =========================================================
-- Dimension Validation Checks
-- =========================================================

-- dim_department_clean
SELECT
  COUNT(*) AS rows_total,
  COUNT(DISTINCT department_id) AS distinct_department_id,
  COUNT(*) - COUNT(DISTINCT department_id) AS duplicate_pk_rows
FROM hr_analytics.dim_department_clean;

SELECT COUNT(*) AS null_department_id_rows
FROM hr_analytics.dim_department_clean
WHERE department_id IS NULL;

SELECT *
FROM hr_analytics.dim_department_clean
WHERE department_name_clean IS NULL
   OR trim(department_name_clean) = '';

SELECT department_id, department_name_clean, cost_center_clean
FROM hr_analytics.dim_department_clean
ORDER BY department_id;


-- dim_location_clean
SELECT
  COUNT(*) AS rows_total,
  COUNT(DISTINCT location_id) AS distinct_location_id,
  COUNT(*) - COUNT(DISTINCT location_id) AS duplicate_pk_rows
FROM hr_analytics.dim_location_clean;

SELECT COUNT(*) AS null_location_id_rows
FROM hr_analytics.dim_location_clean
WHERE location_id IS NULL;

SELECT *
FROM hr_analytics.dim_location_clean
WHERE location_name_clean IS NULL
   OR trim(location_name_clean) = '';

SELECT location_id, location_name_clean, country_clean, region
FROM hr_analytics.dim_location_clean
ORDER BY location_id;

SELECT *
FROM hr_analytics.dim_location_clean
WHERE region NOT IN ('NA', 'EMEA', 'APAC');


-- dim_job_clean
SELECT
  COUNT(*) AS rows_total,
  COUNT(DISTINCT job_id) AS distinct_job_id,
  COUNT(*) - COUNT(DISTINCT job_id) AS duplicate_pk_rows
FROM hr_analytics.dim_job_clean;

SELECT COUNT(*) AS null_job_id_rows
FROM hr_analytics.dim_job_clean
WHERE job_id IS NULL;

SELECT *
FROM hr_analytics.dim_job_clean
WHERE job_title_clean IS NULL
   OR trim(job_title_clean) = '';

SELECT *
FROM hr_analytics.dim_job_clean
WHERE job_level NOT IN ('L1','L2','L3','L4','L5','L6','L7');

SELECT *
FROM hr_analytics.dim_job_clean
WHERE exempt_flag NOT IN ('Y','N');


-- =========================================================
-- Workforce Validation Checks
-- =========================================================

-- fct_employee_snapshot_monthly_clean
SELECT
  COUNT(*) AS rows_total,
  COUNT(DISTINCT concat(employee_id, '||', CAST(month_start AS STRING))) AS distinct_employee_month_key,
  COUNT(*) - COUNT(DISTINCT concat(employee_id, '||', CAST(month_start AS STRING))) AS duplicate_employee_month_rows
FROM hr_analytics.fct_employee_snapshot_monthly_clean;

SELECT
  SUM(CASE WHEN month_start IS NULL THEN 1 ELSE 0 END) AS null_month_start_rows,
  SUM(CASE WHEN employee_id IS NULL OR trim(employee_id) = '' THEN 1 ELSE 0 END) AS null_employee_id_rows
FROM hr_analytics.fct_employee_snapshot_monthly_clean;

SELECT employment_status_clean, COUNT(*) AS row_count
FROM hr_analytics.fct_employee_snapshot_monthly_clean
GROUP BY employment_status_clean
ORDER BY row_count DESC;

SELECT termination_type_clean, COUNT(*) AS row_count
FROM hr_analytics.fct_employee_snapshot_monthly_clean
GROUP BY termination_type_clean
ORDER BY row_count DESC;

SELECT COUNT(*) AS termination_before_hire_rows
FROM hr_analytics.fct_employee_snapshot_monthly_clean
WHERE termination_date IS NOT NULL
  AND hire_date IS NOT NULL
  AND termination_date < hire_date;

SELECT
  month_start,
  COUNT(DISTINCT CASE WHEN employment_status_clean = 'Active' THEN employee_id END) AS active_headcount
FROM hr_analytics.fct_employee_snapshot_monthly_clean
GROUP BY month_start
ORDER BY month_start;

SELECT tenure_band, COUNT(*) AS row_count
FROM hr_analytics.fct_employee_snapshot_monthly_clean
GROUP BY tenure_band
ORDER BY row_count DESC;

SELECT
  COUNT(*) AS rows_total,
  SUM(CASE WHEN fte IS NULL THEN 1 ELSE 0 END) AS fte_null_rows,
  SUM(CASE WHEN base_salary_usd IS NULL THEN 1 ELSE 0 END) AS salary_null_rows,
  MIN(fte) AS min_fte,
  MAX(fte) AS max_fte,
  MIN(base_salary_usd) AS min_salary,
  MAX(base_salary_usd) AS max_salary
FROM hr_analytics.fct_employee_snapshot_monthly_clean;


-- fct_employee_events_clean
SELECT
  COUNT(*) AS rows_total,
  COUNT(DISTINCT event_id) AS distinct_event_id,
  COUNT(*) - COUNT(DISTINCT event_id) AS duplicate_event_id_rows
FROM hr_analytics.fct_employee_events_clean;

SELECT
  SUM(CASE WHEN event_id IS NULL OR trim(event_id) = '' THEN 1 ELSE 0 END) AS null_event_id_rows,
  SUM(CASE WHEN employee_id IS NULL OR trim(employee_id) = '' THEN 1 ELSE 0 END) AS null_employee_id_rows,
  SUM(CASE WHEN event_date IS NULL THEN 1 ELSE 0 END) AS null_event_date_rows
FROM hr_analytics.fct_employee_events_clean;

SELECT event_type_clean, COUNT(*) AS row_count
FROM hr_analytics.fct_employee_events_clean
GROUP BY event_type_clean
ORDER BY row_count DESC;

SELECT termination_type_clean, COUNT(*) AS row_count
FROM hr_analytics.fct_employee_events_clean
GROUP BY termination_type_clean
ORDER BY row_count DESC;

SELECT
  event_month,
  event_type_clean,
  COUNT(*) AS event_count
FROM hr_analytics.fct_employee_events_clean
GROUP BY event_month, event_type_clean
ORDER BY event_month, event_type_clean;

SELECT
  event_type_clean,
  SUM(CASE WHEN termination_type_clean IS NOT NULL THEN 1 ELSE 0 END) AS rows_with_termination_type
FROM hr_analytics.fct_employee_events_clean
GROUP BY event_type_clean
ORDER BY event_type_clean;

SELECT *
FROM hr_analytics.fct_employee_events_clean
WHERE event_type_clean IS NULL;


-- =========================================================
-- Talent Acquisition Validation Checks
-- =========================================================

-- fct_requisitions_clean
SELECT
  COUNT(*) AS rows_total,
  COUNT(DISTINCT req_id) AS distinct_req_id,
  COUNT(*) - COUNT(DISTINCT req_id) AS duplicate_req_id_rows
FROM hr_analytics.fct_requisitions_clean;

SELECT
  SUM(CASE WHEN req_id IS NULL OR trim(req_id) = '' THEN 1 ELSE 0 END) AS null_req_id_rows,
  SUM(CASE WHEN opened_date IS NULL THEN 1 ELSE 0 END) AS null_opened_date_rows
FROM hr_analytics.fct_requisitions_clean;

SELECT req_status_clean, COUNT(*) AS row_count
FROM hr_analytics.fct_requisitions_clean
GROUP BY req_status_clean
ORDER BY row_count DESC;

SELECT headcount_type_clean, COUNT(*) AS row_count
FROM hr_analytics.fct_requisitions_clean
GROUP BY headcount_type_clean
ORDER BY row_count DESC;

SELECT
  SUM(CASE WHEN req_status_clean IN ('Closed','Cancelled') AND closed_date IS NULL THEN 1 ELSE 0 END) AS closed_or_cancelled_missing_closed_date_rows,
  SUM(CASE WHEN req_status_clean = 'Open' AND closed_date IS NOT NULL THEN 1 ELSE 0 END) AS open_with_closed_date_rows,
  SUM(CASE WHEN closed_date IS NOT NULL AND opened_date IS NOT NULL AND closed_date < opened_date THEN 1 ELSE 0 END) AS closed_before_opened_rows
FROM hr_analytics.fct_requisitions_clean;

SELECT
  COUNT(*) AS closed_reqs,
  AVG(time_to_fill_days) AS avg_time_to_fill_days,
  MIN(time_to_fill_days) AS min_time_to_fill_days,
  MAX(time_to_fill_days) AS max_time_to_fill_days
FROM hr_analytics.fct_requisitions_clean
WHERE req_status_clean = 'Closed';

SELECT
  COUNT(*) AS open_reqs,
  AVG(datediff(current_date(), opened_date)) AS avg_open_req_age_days,
  MIN(datediff(current_date(), opened_date)) AS min_open_req_age_days,
  MAX(datediff(current_date(), opened_date)) AS max_open_req_age_days
FROM hr_analytics.fct_requisitions_clean
WHERE req_status_clean = 'Open'
  AND opened_date IS NOT NULL;

SELECT opened_month, COUNT(*) AS reqs_opened
FROM hr_analytics.fct_requisitions_clean
GROUP BY opened_month
ORDER BY opened_month;

SELECT closed_month, COUNT(*) AS reqs_closed
FROM hr_analytics.fct_requisitions_clean
WHERE closed_month IS NOT NULL
GROUP BY closed_month
ORDER BY closed_month;


-- fct_candidates_clean
SELECT
  COUNT(*) AS rows_total,
  COUNT(DISTINCT candidate_app_id) AS distinct_candidate_app_id,
  COUNT(*) - COUNT(DISTINCT candidate_app_id) AS duplicate_candidate_app_id_rows
FROM hr_analytics.fct_candidates_clean;

SELECT
  SUM(CASE WHEN candidate_app_id IS NULL OR trim(candidate_app_id) = '' THEN 1 ELSE 0 END) AS null_candidate_app_id_rows,
  SUM(CASE WHEN candidate_id IS NULL OR trim(candidate_id) = '' THEN 1 ELSE 0 END) AS null_candidate_id_rows,
  SUM(CASE WHEN req_id IS NULL OR trim(req_id) = '' THEN 1 ELSE 0 END) AS null_req_id_rows,
  SUM(CASE WHEN application_date IS NULL THEN 1 ELSE 0 END) AS null_application_date_rows
FROM hr_analytics.fct_candidates_clean;

SELECT final_outcome_clean, COUNT(*) AS row_count
FROM hr_analytics.fct_candidates_clean
GROUP BY final_outcome_clean
ORDER BY row_count DESC;

SELECT source_clean, COUNT(*) AS row_count
FROM hr_analytics.fct_candidates_clean
GROUP BY source_clean
ORDER BY row_count DESC;

SELECT current_stage_clean, COUNT(*) AS row_count
FROM hr_analytics.fct_candidates_clean
GROUP BY current_stage_clean
ORDER BY row_count DESC;

SELECT
  SUM(CASE WHEN offer_date IS NOT NULL AND application_date IS NOT NULL AND offer_date < application_date THEN 1 ELSE 0 END) AS offer_before_application_rows,
  SUM(CASE WHEN accept_date IS NOT NULL AND offer_date IS NOT NULL AND accept_date < offer_date THEN 1 ELSE 0 END) AS accept_before_offer_rows,
  SUM(CASE WHEN rejection_date IS NOT NULL AND application_date IS NOT NULL AND rejection_date < application_date THEN 1 ELSE 0 END) AS rejection_before_application_rows
FROM hr_analytics.fct_candidates_clean;

SELECT
  SUM(CASE WHEN final_outcome_clean = 'Hired' AND accept_date IS NULL THEN 1 ELSE 0 END) AS hired_without_accept_rows,
  SUM(CASE WHEN final_outcome_clean = 'Rejected' AND rejection_date IS NULL THEN 1 ELSE 0 END) AS rejected_without_rejection_date_rows
FROM hr_analytics.fct_candidates_clean;

SELECT
  SUM(is_hired_flag) AS hired_apps,
  SUM(has_offer_flag) AS apps_with_offer,
  SUM(has_accept_flag) AS apps_with_accept,
  AVG(days_app_to_offer) AS avg_days_app_to_offer,
  AVG(days_offer_to_accept) AS avg_days_offer_to_accept
FROM hr_analytics.fct_candidates_clean;


-- fct_candidate_stage_events_clean
SELECT
  COUNT(*) AS rows_total,
  COUNT(DISTINCT stage_event_id) AS distinct_stage_event_id,
  COUNT(*) - COUNT(DISTINCT stage_event_id) AS duplicate_stage_event_id_rows
FROM hr_analytics.fct_candidate_stage_events_clean;

SELECT
  SUM(CASE WHEN stage_event_id IS NULL OR trim(stage_event_id) = '' THEN 1 ELSE 0 END) AS null_stage_event_id_rows,
  SUM(CASE WHEN candidate_app_id IS NULL OR trim(candidate_app_id) = '' THEN 1 ELSE 0 END) AS null_candidate_app_id_rows,
  SUM(CASE WHEN stage_date IS NULL THEN 1 ELSE 0 END) AS null_stage_date_rows
FROM hr_analytics.fct_candidate_stage_events_clean;

SELECT stage_name_clean, COUNT(*) AS row_count
FROM hr_analytics.fct_candidate_stage_events_clean
GROUP BY stage_name_clean
ORDER BY row_count DESC;

SELECT stage_status_clean, COUNT(*) AS row_count
FROM hr_analytics.fct_candidate_stage_events_clean
GROUP BY stage_status_clean
ORDER BY row_count DESC;

SELECT stage_order, COUNT(*) AS row_count
FROM hr_analytics.fct_candidate_stage_events_clean
GROUP BY stage_order
ORDER BY stage_order;

SELECT stage_month, stage_name_clean, COUNT(*) AS stage_events
FROM hr_analytics.fct_candidate_stage_events_clean
GROUP BY stage_month, stage_name_clean
ORDER BY stage_month, stage_name_clean;

SELECT *
FROM hr_analytics.fct_candidate_stage_events_clean
WHERE stage_order = 99
LIMIT 50;


-- =========================================================
-- Cross-Table Validation Checks
-- =========================================================

SELECT
  COUNT(*) AS candidate_rows,
  SUM(CASE WHEN r.req_id IS NULL THEN 1 ELSE 0 END) AS candidate_rows_missing_req_match
FROM hr_analytics.fct_candidates_clean c
LEFT JOIN hr_analytics.fct_requisitions_clean r
  ON c.req_id = r.req_id;

SELECT
  COUNT(*) AS stage_event_rows,
  SUM(CASE WHEN c.candidate_app_id IS NULL THEN 1 ELSE 0 END) AS stage_events_missing_candidate_app_match
FROM hr_analytics.fct_candidate_stage_events_clean s
LEFT JOIN hr_analytics.fct_candidates_clean c
  ON s.candidate_app_id = c.candidate_app_id;

SELECT
  COUNT(*) AS snapshot_rows,
  SUM(CASE WHEN d.department_id IS NULL THEN 1 ELSE 0 END) AS missing_department_match_rows,
  SUM(CASE WHEN l.location_id IS NULL THEN 1 ELSE 0 END) AS missing_location_match_rows,
  SUM(CASE WHEN j.job_id IS NULL THEN 1 ELSE 0 END) AS missing_job_match_rows
FROM hr_analytics.fct_employee_snapshot_monthly_clean s
LEFT JOIN hr_analytics.dim_department_clean d
  ON s.department_id = d.department_id
LEFT JOIN hr_analytics.dim_location_clean l
  ON s.location_id = l.location_id
LEFT JOIN hr_analytics.dim_job_clean j
  ON s.job_id = j.job_id;

SELECT
  COUNT(*) AS req_rows,
  SUM(CASE WHEN d.department_id IS NULL THEN 1 ELSE 0 END) AS missing_department_match_rows,
  SUM(CASE WHEN l.location_id IS NULL THEN 1 ELSE 0 END) AS missing_location_match_rows,
  SUM(CASE WHEN j.job_id IS NULL THEN 1 ELSE 0 END) AS missing_job_match_rows
FROM hr_analytics.fct_requisitions_clean r
LEFT JOIN hr_analytics.dim_department_clean d
  ON r.department_id = d.department_id
LEFT JOIN hr_analytics.dim_location_clean l
  ON r.location_id = l.location_id
LEFT JOIN hr_analytics.dim_job_clean j
  ON r.job_id = j.job_id;

SELECT
  (SELECT COUNT(*) FROM hr_analytics.fct_candidates_clean WHERE final_outcome_clean = 'Hired') AS hired_candidate_apps,
  (SELECT COUNT(DISTINCT candidate_app_id) FROM hr_analytics.fct_candidate_stage_events_clean WHERE stage_name_clean = 'Hired') AS candidate_apps_with_hired_stage;

SELECT
  r.req_status_clean,
  COUNT(*) AS candidate_apps
FROM hr_analytics.fct_candidates_clean c
LEFT JOIN hr_analytics.fct_requisitions_clean r
  ON c.req_id = r.req_id
GROUP BY r.req_status_clean
ORDER BY candidate_apps DESC;

SELECT event_type_clean, COUNT(*) AS event_count
FROM hr_analytics.fct_employee_events_clean
GROUP BY event_type_clean
ORDER BY event_count DESC;

SELECT c.*
FROM hr_analytics.fct_candidates_clean c
LEFT JOIN hr_analytics.fct_requisitions_clean r
  ON c.req_id = r.req_id
WHERE r.req_id IS NULL
LIMIT 25;

SELECT s.*
FROM hr_analytics.fct_candidate_stage_events_clean s
LEFT JOIN hr_analytics.fct_candidates_clean c
  ON s.candidate_app_id = c.candidate_app_id
WHERE c.candidate_app_id IS NULL
LIMIT 25;
