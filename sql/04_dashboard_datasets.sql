-- =========================================================
-- Page 1 — Workforce Monthly
-- v_tableau_page1_workforce_monthly_region
-- =========================================================

CREATE OR REPLACE VIEW hr_analytics.v_tableau_page1_workforce_monthly_region AS

WITH snapshot_bounds AS (
  SELECT
    MIN(month_start) AS min_month_start,
    MAX(month_start) AS max_month_start
  FROM hr_analytics.fct_employee_snapshot_monthly_clean
),

month_domain AS (
  SELECT DISTINCT
    month_start
  FROM hr_analytics.fct_employee_snapshot_monthly_clean
),

region_domain AS (
  SELECT DISTINCT
    region
  FROM hr_analytics.dim_location_clean
  WHERE region IS NOT NULL
),

month_region_scaffold AS (
  SELECT
    m.month_start,
    r.region
  FROM month_domain m
  CROSS JOIN region_domain r
),

monthly_headcount AS (
  SELECT
    s.month_start,
    l.region,
    COUNT(DISTINCT CASE WHEN s.is_active_flag = 1 THEN s.employee_id END) AS active_headcount
  FROM hr_analytics.fct_employee_snapshot_monthly_clean s
  LEFT JOIN hr_analytics.dim_location_clean l
    ON s.location_id = l.location_id
  GROUP BY
    s.month_start,
    l.region
),

monthly_headcount_with_prior AS (
  SELECT
    month_start,
    region,
    COALESCE(active_headcount, 0) AS active_headcount,
    LAG(COALESCE(active_headcount, 0)) OVER (
      PARTITION BY region
      ORDER BY month_start
    ) AS prior_month_active_headcount
  FROM monthly_headcount
),

monthly_events AS (
  SELECT
    e.event_month AS month_start,
    l.region,
    COUNT(CASE WHEN e.event_type_clean = 'Hire' THEN 1 END) AS hires,
    COUNT(CASE WHEN e.event_type_clean = 'Termination' THEN 1 END) AS separations,
    COUNT(CASE WHEN e.event_type_clean = 'Promotion' THEN 1 END) AS promotions,
    COUNT(CASE WHEN e.event_type_clean = 'Transfer' THEN 1 END) AS transfers
  FROM hr_analytics.fct_employee_events_clean e
  LEFT JOIN hr_analytics.fct_employee_snapshot_monthly_clean s
    ON e.employee_id = s.employee_id
   AND e.event_month = s.month_start
  LEFT JOIN hr_analytics.dim_location_clean l
    ON s.location_id = l.location_id
  CROSS JOIN snapshot_bounds b
  WHERE e.event_month >= b.min_month_start
    AND e.event_month <= b.max_month_start
  GROUP BY
    e.event_month,
    l.region
),

monthly_events_with_prior AS (
  SELECT
    month_start,
    region,
    COALESCE(hires, 0) AS hires,
    COALESCE(separations, 0) AS separations,
    COALESCE(promotions, 0) AS promotions,
    COALESCE(transfers, 0) AS transfers,
    LAG(COALESCE(hires, 0)) OVER (
      PARTITION BY region
      ORDER BY month_start
    ) AS prior_month_hires
  FROM monthly_events
)

SELECT
  s.month_start,
  s.region,
  COALESCE(h.active_headcount, 0) AS active_headcount,
  COALESCE(h.prior_month_active_headcount, 0) AS prior_month_active_headcount,
  COALESCE(h.active_headcount, 0) - COALESCE(h.prior_month_active_headcount, 0) AS net_change_vs_prior_month,
  COALESCE(e.hires, 0) AS hires,
  COALESCE(e.prior_month_hires, 0) AS prior_month_hires,
  COALESCE(e.hires, 0) - COALESCE(e.prior_month_hires, 0) AS net_change_hires_vs_prior_month,
  COALESCE(e.separations, 0) AS separations,
  COALESCE(e.promotions, 0) AS promotions,
  COALESCE(e.transfers, 0) AS transfers,
  COALESCE(e.promotions, 0) + COALESCE(e.transfers, 0) AS internal_mobility_events,
  CASE
    WHEN ((COALESCE(h.active_headcount, 0) + COALESCE(h.prior_month_active_headcount, 0)) / 2.0) > 0
    THEN COALESCE(e.separations, 0)
         / ((COALESCE(h.active_headcount, 0) + COALESCE(h.prior_month_active_headcount, 0)) / 2.0)
    ELSE NULL
  END AS attrition_rate
FROM month_region_scaffold s
LEFT JOIN monthly_headcount_with_prior h
  ON s.month_start = h.month_start
 AND s.region = h.region
LEFT JOIN monthly_events_with_prior e
  ON s.month_start = e.month_start
 AND s.region = e.region
ORDER BY
  s.month_start,
  s.region;

SELECT *
FROM hr_analytics.v_tableau_page1_workforce_monthly_region
ORDER BY month_start, region;


-- =========================================================
-- Page 1 — Headcount Segments
-- v_tableau_page1_headcount_segments
-- =========================================================

CREATE OR REPLACE VIEW hr_analytics.v_tableau_page1_headcount_segments AS
SELECT
  s.month_start,
  d.department_name_clean,
  d.org_group,
  l.region,
  l.location_name_clean,
  l.city,
  l.state_province,
  l.country_clean,
  j.job_level,
  COUNT(DISTINCT s.employee_id) AS active_headcount,
  AVG(s.fte) AS avg_fte
FROM hr_analytics.fct_employee_snapshot_monthly_clean s
LEFT JOIN hr_analytics.dim_department_clean d
  ON s.department_id = d.department_id
LEFT JOIN hr_analytics.dim_location_clean l
  ON s.location_id = l.location_id
LEFT JOIN hr_analytics.dim_job_clean j
  ON s.job_id = j.job_id
WHERE s.is_active_flag = 1
GROUP BY
  s.month_start,
  d.department_name_clean,
  d.org_group,
  l.region,
  l.location_name_clean,
  l.city,
  l.state_province,
  l.country_clean,
  j.job_level
ORDER BY s.month_start, active_headcount DESC;

SELECT *
FROM hr_analytics.v_tableau_page1_headcount_segments
ORDER BY month_start, active_headcount DESC;


-- =========================================================
-- Page 1 — Attrition Drivers
-- v_tableau_page1_attrition_drivers_region
-- =========================================================

CREATE OR REPLACE VIEW hr_analytics.v_tableau_page1_attrition_drivers_region AS

WITH snapshot_bounds AS (
  SELECT
    MIN(month_start) AS min_month_start,
    MAX(month_start) AS max_month_start
  FROM hr_analytics.fct_employee_snapshot_monthly_clean
),

dept_region_headcount AS (
  SELECT
    s.month_start,
    s.department_id,
    l.region,
    COUNT(DISTINCT CASE WHEN s.is_active_flag = 1 THEN s.employee_id END) AS active_headcount
  FROM hr_analytics.fct_employee_snapshot_monthly_clean s
  LEFT JOIN hr_analytics.dim_location_clean l
    ON s.location_id = l.location_id
  GROUP BY
    s.month_start,
    s.department_id,
    l.region
),

dept_region_headcount_with_prior AS (
  SELECT
    month_start,
    department_id,
    region,
    active_headcount,
    LAG(active_headcount) OVER (
      PARTITION BY department_id, region
      ORDER BY month_start
    ) AS prior_month_active_headcount
  FROM dept_region_headcount
),

termination_events_enriched AS (
  SELECT
    e.event_id,
    e.employee_id,
    e.event_month AS month_start,
    COALESCE(
      s.department_id,
      e.from_department_id,
      e.to_department_id
    ) AS department_id,
    l.region,
    CASE
      WHEN TRIM(COALESCE(e.termination_type_clean, '')) = '' THEN 'Data Issue'
      WHEN LOWER(TRIM(e.termination_type_clean)) = 'voluntary' THEN 'Voluntary'
      WHEN LOWER(TRIM(e.termination_type_clean)) = 'involuntary' THEN 'Involuntary'
      ELSE 'Other'
    END AS termination_type_group,
    COALESCE(s.tenure_band, 'Unknown') AS tenure_band
  FROM hr_analytics.fct_employee_events_clean e
  LEFT JOIN hr_analytics.fct_employee_snapshot_monthly_clean s
    ON e.employee_id = s.employee_id
   AND e.event_month = s.month_start
  LEFT JOIN hr_analytics.dim_location_clean l
    ON s.location_id = l.location_id
  CROSS JOIN snapshot_bounds b
  WHERE e.event_type_clean = 'Termination'
    AND e.event_month >= b.min_month_start
    AND e.event_month <= b.max_month_start
),

dept_region_terminations AS (
  SELECT
    month_start,
    department_id,
    region,
    COUNT(DISTINCT event_id) AS department_terminations
  FROM termination_events_enriched
  GROUP BY
    month_start,
    department_id,
    region
),

dept_region_terminations_with_prior AS (
  SELECT
    month_start,
    department_id,
    region,
    department_terminations,
    LAG(department_terminations) OVER (
      PARTITION BY department_id, region
      ORDER BY month_start
    ) AS prior_month_department_terminations
  FROM dept_region_terminations
),

dept_region_monthly_base AS (
  SELECT
    h.month_start,
    h.department_id,
    h.region,
    h.active_headcount,
    h.prior_month_active_headcount,
    h.active_headcount - COALESCE(h.prior_month_active_headcount, 0) AS net_change_active_headcount,
    COALESCE(t.department_terminations, 0) AS department_terminations,
    COALESCE(t.prior_month_department_terminations, 0) AS prior_month_department_terminations,
    COALESCE(t.department_terminations, 0) - COALESCE(t.prior_month_department_terminations, 0) AS net_change_department_terminations,
    CASE
      WHEN ((h.active_headcount + h.prior_month_active_headcount) / 2.0) > 0 THEN
        COALESCE(t.department_terminations, 0) / ((h.active_headcount + h.prior_month_active_headcount) / 2.0)
      ELSE NULL
    END AS department_attrition_rate
  FROM dept_region_headcount_with_prior h
  LEFT JOIN dept_region_terminations_with_prior t
    ON h.month_start = t.month_start
   AND h.department_id = t.department_id
   AND h.region = t.region
),

termination_type_driver AS (
  SELECT
    month_start,
    department_id,
    region,
    'Termination Type' AS driver_group,
    termination_type_group AS driver_value,
    COUNT(DISTINCT event_id) AS driver_terminations
  FROM termination_events_enriched
  GROUP BY
    month_start,
    department_id,
    region,
    termination_type_group
),

termination_type_driver_with_prior AS (
  SELECT
    month_start,
    department_id,
    region,
    driver_group,
    driver_value,
    driver_terminations,
    LAG(driver_terminations) OVER (
      PARTITION BY department_id, region, driver_group, driver_value
      ORDER BY month_start
    ) AS prior_month_driver_terminations
  FROM termination_type_driver
),

tenure_band_driver AS (
  SELECT
    month_start,
    department_id,
    region,
    'Tenure Band' AS driver_group,
    tenure_band AS driver_value,
    COUNT(DISTINCT event_id) AS driver_terminations
  FROM termination_events_enriched
  GROUP BY
    month_start,
    department_id,
    region,
    tenure_band
),

tenure_band_driver_with_prior AS (
  SELECT
    month_start,
    department_id,
    region,
    driver_group,
    driver_value,
    driver_terminations,
    LAG(driver_terminations) OVER (
      PARTITION BY department_id, region, driver_group, driver_value
      ORDER BY month_start
    ) AS prior_month_driver_terminations
  FROM tenure_band_driver
),

all_driver_rows AS (
  SELECT
    month_start,
    department_id,
    region,
    driver_group,
    driver_value,
    driver_terminations,
    prior_month_driver_terminations
  FROM termination_type_driver_with_prior

  UNION ALL

  SELECT
    month_start,
    department_id,
    region,
    driver_group,
    driver_value,
    driver_terminations,
    prior_month_driver_terminations
  FROM tenure_band_driver_with_prior
)

SELECT
  b.month_start,
  b.department_id,
  d.department_name_clean,
  d.org_group,
  b.region,
  b.active_headcount,
  b.prior_month_active_headcount,
  b.net_change_active_headcount,
  b.department_terminations,
  b.prior_month_department_terminations,
  b.net_change_department_terminations,
  b.department_attrition_rate,
  a.driver_group,
  a.driver_value,
  COALESCE(a.driver_terminations, 0) AS driver_terminations,
  COALESCE(a.prior_month_driver_terminations, 0) AS prior_month_driver_terminations,
  COALESCE(a.driver_terminations, 0) - COALESCE(a.prior_month_driver_terminations, 0) AS net_change_driver_terminations,
  CASE
    WHEN ((b.active_headcount + b.prior_month_active_headcount) / 2.0) > 0 THEN
      COALESCE(a.driver_terminations, 0) / ((b.active_headcount + b.prior_month_active_headcount) / 2.0)
    ELSE NULL
  END AS driver_attrition_rate
FROM dept_region_monthly_base b
LEFT JOIN all_driver_rows a
  ON b.month_start = a.month_start
 AND b.department_id = a.department_id
 AND b.region = a.region
LEFT JOIN hr_analytics.dim_department_clean d
  ON b.department_id = d.department_id
ORDER BY
  b.month_start,
  d.department_name_clean,
  b.region,
  a.driver_group,
  a.driver_value;

SELECT *
FROM hr_analytics.v_tableau_page1_attrition_drivers_region
ORDER BY month_start, department_name_clean, region, driver_group, driver_value;


-- =========================================================
-- Page 2 — TA Monthly Core
-- v_tableau_page2_ta_monthly_core_region
-- =========================================================

CREATE OR REPLACE VIEW hr_analytics.v_tableau_page2_ta_monthly_core_region AS
WITH date_bounds AS (
  SELECT
    DATE '2023-03-01' AS min_m,
    MAX(dt) AS max_m
  FROM (
    SELECT CAST(date_trunc('month', opened_date) AS DATE) AS dt
    FROM hr_analytics.fct_requisitions_clean
    WHERE opened_date IS NOT NULL
      AND opened_date >= DATE '2023-03-01'

    UNION ALL

    SELECT CAST(date_trunc('month', application_date) AS DATE) AS dt
    FROM hr_analytics.fct_candidates_clean
    WHERE application_date IS NOT NULL
      AND application_date >= DATE '2023-03-01'

    UNION ALL

    SELECT CAST(date_trunc('month', closed_date) AS DATE) AS dt
    FROM hr_analytics.fct_requisitions_clean
    WHERE closed_date IS NOT NULL
      AND closed_date >= DATE '2023-03-01'
  ) x
),

months AS (
  SELECT explode(sequence(min_m, max_m, interval 1 month)) AS month_start
  FROM date_bounds
),

regions AS (
  SELECT DISTINCT region
  FROM hr_analytics.dim_location_clean
  WHERE region IS NOT NULL
),

month_region_scaffold AS (
  SELECT
    m.month_start,
    r.region
  FROM months m
  CROSS JOIN regions r
),

open_backlog AS (
  SELECT
    m.month_start,
    l.region,
    COUNT(DISTINCT rq.req_id) AS open_reqs_end_of_month
  FROM months m
  JOIN hr_analytics.fct_requisitions_clean rq
    ON rq.opened_date IS NOT NULL
   AND rq.opened_date >= DATE '2023-03-01'
   AND rq.opened_date <= last_day(m.month_start)
   AND (rq.closed_date IS NULL OR rq.closed_date > last_day(m.month_start))
  LEFT JOIN hr_analytics.dim_location_clean l
    ON rq.location_id = l.location_id
  WHERE l.region IS NOT NULL
  GROUP BY
    m.month_start,
    l.region
),

req_opened AS (
  SELECT
    rq.opened_month AS month_start,
    l.region,
    COUNT(*) AS total_reqs_opened,
    SUM(CASE WHEN rq.req_status_clean = 'Open' THEN 1 ELSE 0 END) AS open_reqs_opened,
    SUM(CASE WHEN rq.req_status_clean = 'Closed' THEN 1 ELSE 0 END) AS closed_reqs_opened,
    SUM(CASE WHEN rq.req_status_clean = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_reqs_opened
  FROM hr_analytics.fct_requisitions_clean rq
  LEFT JOIN hr_analytics.dim_location_clean l
    ON rq.location_id = l.location_id
  WHERE rq.opened_month IS NOT NULL
    AND rq.opened_month >= DATE '2023-03-01'
    AND l.region IS NOT NULL
  GROUP BY
    rq.opened_month,
    l.region
),

cand_monthly AS (
  SELECT
    CAST(date_trunc('month', c.application_date) AS DATE) AS month_start,
    l.region,
    COUNT(*) AS applications,
    SUM(c.has_offer_flag) AS offers,
    SUM(c.has_accept_flag) AS accepts,
    SUM(c.is_hired_flag) AS hires
  FROM hr_analytics.fct_candidates_clean c
  LEFT JOIN hr_analytics.fct_requisitions_clean rq
    ON c.req_id = rq.req_id
  LEFT JOIN hr_analytics.dim_location_clean l
    ON rq.location_id = l.location_id
  WHERE c.application_date IS NOT NULL
    AND c.application_date >= DATE '2023-03-01'
    AND l.region IS NOT NULL
  GROUP BY
    CAST(date_trunc('month', c.application_date) AS DATE),
    l.region
),

ttf_monthly AS (
  SELECT
    rq.closed_month AS month_start,
    l.region,
    AVG(rq.time_to_fill_days) AS avg_time_to_fill_days
  FROM hr_analytics.fct_requisitions_clean rq
  LEFT JOIN hr_analytics.dim_location_clean l
    ON rq.location_id = l.location_id
  WHERE rq.req_status_clean = 'Closed'
    AND rq.time_to_fill_days IS NOT NULL
    AND rq.closed_month IS NOT NULL
    AND rq.closed_month >= DATE '2023-03-01'
    AND l.region IS NOT NULL
  GROUP BY
    rq.closed_month,
    l.region
)

SELECT
  s.month_start,
  s.region,
  COALESCE(ob.open_reqs_end_of_month, 0) AS open_reqs_end_of_month,
  COALESCE(ro.total_reqs_opened, 0) AS total_reqs_opened,
  COALESCE(ro.open_reqs_opened, 0) AS open_reqs_opened,
  COALESCE(ro.closed_reqs_opened, 0) AS closed_reqs_opened,
  COALESCE(ro.cancelled_reqs_opened, 0) AS cancelled_reqs_opened,
  COALESCE(c.applications, 0) AS applications,
  COALESCE(c.offers, 0) AS offers,
  COALESCE(c.accepts, 0) AS accepts,
  COALESCE(c.hires, 0) AS hires,
  CASE
    WHEN COALESCE(c.offers, 0) > 0
      THEN COALESCE(c.accepts, 0) * 1.0 / COALESCE(c.offers, 0)
    ELSE NULL
  END AS offer_acceptance_rate,
  CASE
    WHEN COALESCE(c.accepts, 0) > 0
      THEN COALESCE(c.hires, 0) * 1.0 / COALESCE(c.accepts, 0)
    ELSE NULL
  END AS hire_start_rate,
  CASE
    WHEN COALESCE(c.applications, 0) > 0
      THEN COALESCE(c.hires, 0) * 1.0 / COALESCE(c.applications, 0)
    ELSE NULL
  END AS hire_conversion_rate,
  t.avg_time_to_fill_days
FROM month_region_scaffold s
LEFT JOIN open_backlog ob
  ON s.month_start = ob.month_start
 AND s.region = ob.region
LEFT JOIN req_opened ro
  ON s.month_start = ro.month_start
 AND s.region = ro.region
LEFT JOIN cand_monthly c
  ON s.month_start = c.month_start
 AND s.region = c.region
LEFT JOIN ttf_monthly t
  ON s.month_start = t.month_start
 AND s.region = t.region
ORDER BY
  s.month_start,
  s.region;

SELECT *
FROM hr_analytics.v_tableau_page2_ta_monthly_core_region
ORDER BY month_start, region;


-- =========================================================
-- Page 2 — Source Quality
-- v_tableau_page2_source_quality_region
-- =========================================================

CREATE OR REPLACE VIEW hr_analytics.v_tableau_page2_source_quality_region AS
SELECT
  CAST(date_trunc('month', c.application_date) AS DATE) AS month_start,
  l.region,
  c.source_clean,
  COUNT(*) AS applications,
  SUM(c.has_offer_flag) AS offers,
  SUM(c.has_accept_flag) AS accepts,
  SUM(c.is_hired_flag) AS hires,
  CASE
    WHEN SUM(c.has_offer_flag) > 0
      THEN SUM(c.has_accept_flag) * 1.0 / SUM(c.has_offer_flag)
    ELSE NULL
  END AS offer_acceptance_rate,
  CASE
    WHEN SUM(c.has_accept_flag) > 0
      THEN SUM(c.is_hired_flag) * 1.0 / SUM(c.has_accept_flag)
    ELSE NULL
  END AS hire_start_rate,
  CASE
    WHEN COUNT(*) > 0
      THEN SUM(c.is_hired_flag) * 1.0 / COUNT(*)
    ELSE NULL
  END AS hire_conversion_rate
FROM hr_analytics.fct_candidates_clean c
LEFT JOIN hr_analytics.fct_requisitions_clean rq
  ON c.req_id = rq.req_id
LEFT JOIN hr_analytics.dim_location_clean l
  ON rq.location_id = l.location_id
WHERE c.application_date IS NOT NULL
  AND c.application_date >= DATE '2023-03-01'
  AND l.region IS NOT NULL
GROUP BY
  CAST(date_trunc('month', c.application_date) AS DATE),
  l.region,
  c.source_clean
ORDER BY
  month_start,
  region,
  applications DESC;

SELECT *
FROM hr_analytics.v_tableau_page2_source_quality_region
ORDER BY month_start, applications DESC;


-- =========================================================
-- Page 2 — Funnel Stages
-- v_tableau_page2_funnel_stages_region
-- =========================================================

CREATE OR REPLACE VIEW hr_analytics.v_tableau_page2_funnel_stages_region AS
WITH stage_reach AS (
  SELECT DISTINCT
    s.stage_month AS month_start,
    l.region,
    s.stage_order,
    s.stage_name_clean,
    s.candidate_app_id,
    c.has_accept_flag,
    c.is_hired_flag
  FROM hr_analytics.fct_candidate_stage_events_clean s
  JOIN hr_analytics.fct_candidates_clean c
    ON s.candidate_app_id = c.candidate_app_id
  LEFT JOIN hr_analytics.fct_requisitions_clean rq
    ON c.req_id = rq.req_id
  LEFT JOIN hr_analytics.dim_location_clean l
    ON rq.location_id = l.location_id
  WHERE s.stage_month IS NOT NULL
    AND s.stage_month >= DATE '2023-03-01'
    AND l.region IS NOT NULL
    AND s.stage_order IS NOT NULL
    AND s.stage_name_clean IS NOT NULL
)

SELECT
  month_start,
  region,
  stage_order,
  stage_name_clean,
  COUNT(DISTINCT candidate_app_id) AS candidate_apps,
  SUM(CASE WHEN has_accept_flag = 1 THEN 1 ELSE 0 END) AS accepts,
  SUM(CASE WHEN is_hired_flag = 1 THEN 1 ELSE 0 END) AS hires,
  SUM(CASE WHEN has_accept_flag = 1 AND is_hired_flag = 0 THEN 1 ELSE 0 END) AS accepted_not_hired
FROM stage_reach
GROUP BY
  month_start,
  region,
  stage_order,
  stage_name_clean
ORDER BY
  month_start,
  region,
  stage_order;

SELECT *
FROM hr_analytics.v_tableau_page2_funnel_stages_region
ORDER BY month_start, region, stage_order;


-- =========================================================
-- Page 2 — Open Req Priority
-- v_tableau_page2_open_req_priority
-- =========================================================

CREATE OR REPLACE VIEW hr_analytics.v_tableau_page2_open_req_priority AS
SELECT
  r.req_id,
  r.opened_date,
  r.opened_month,
  r.req_status_clean,
  r.headcount_type_clean,
  r.department_id,
  d.department_name_clean,
  d.org_group,
  r.location_id,
  l.region,
  l.location_name_clean,
  r.job_id,
  j.job_title_clean,
  j.job_level,
  r.hiring_manager_id,
  r.recruiter_id,
  datediff(current_date(), r.opened_date) AS req_age_days,
  CASE
    WHEN datediff(current_date(), r.opened_date) BETWEEN 0 AND 30 THEN '0-30'
    WHEN datediff(current_date(), r.opened_date) BETWEEN 31 AND 60 THEN '31-60'
    WHEN datediff(current_date(), r.opened_date) BETWEEN 61 AND 90 THEN '61-90'
    WHEN datediff(current_date(), r.opened_date) >= 91 THEN '90+'
    ELSE 'Unknown'
  END AS req_age_bucket,
  CASE
    WHEN r.opened_date IS NOT NULL
     AND r.opened_date >= DATE '2023-03-01'
     AND (r.closed_date IS NULL OR r.closed_date > current_date())
    THEN 1
    ELSE 0
  END AS is_currently_open_by_dates
FROM hr_analytics.fct_requisitions_clean r
LEFT JOIN hr_analytics.dim_department_clean d
  ON r.department_id = d.department_id
LEFT JOIN hr_analytics.dim_location_clean l
  ON r.location_id = l.location_id
LEFT JOIN hr_analytics.dim_job_clean j
  ON r.job_id = j.job_id
WHERE r.opened_date IS NOT NULL
  AND r.opened_date >= DATE '2023-03-01';

SELECT *
FROM hr_analytics.v_tableau_page2_open_req_priority
ORDER BY is_currently_open_by_dates DESC, req_age_days DESC, opened_date;
