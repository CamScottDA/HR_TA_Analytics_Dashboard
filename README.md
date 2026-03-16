# HR + Talent Acquisition Analytics Dashboard (Databricks SQL + Tableau)

A 2-page analytics dashboard built with Databricks SQL and Tableau to evaluate workforce health, attrition patterns, hiring performance, and recruiting funnel quality.

## Tableau Public (Interactive)
Tableau Dashboard:
https://public.tableau.com/app/profile/cameron.scott3127/vizzes

**Note:** Tableau is currently inconsistent with direct dashboard links, so this repo references my Tableau Public vizzes homepage for access.

## Screenshots

### Page 1 — Workforce Health
![Page 1 — Workforce Health](docs/screenshots/page1_workforce_health.png)

### Page 2 — Talent Acquisition Funnel
![Page 2 — Talent Acquisition Funnel](docs/screenshots/page2_talent_acquisition_funnel.png)

## What this project demonstrates
- Multi-table HR and Talent Acquisition data modeling
- Data cleaning and standardization across messy source files
- QA and relationship validation across dimensions and fact tables
- Metric-ready transformation logic for workforce and recruiting analytics
- Dashboard planning tied directly to stakeholder questions
- Clear communication through documented SQL, supporting notes, and dashboard walkthrough structure

## Dashboard pages (what each answers)
**Page 1 — Workforce Health**
- How is headcount changing over time?
- What does attrition look like across the business?
- Which departments or tenure groups are contributing most to workforce exits?
- How should leaders interpret workforce health trends using filterable views by year, quarter, and region?

**Page 2 — Talent Acquisition Funnel**
- How quickly are requisitions being filled?
- Which recruiting sources drive the best mix of volume and hiring quality?
- Where are candidates progressing or dropping off in the funnel?
- What does current funnel health suggest about recruiting priorities and bottlenecks?

## What I discovered from my analysis
- **Attrition needs context, not just totals:** termination counts alone can overstate the story, so separating attrition rate from raw terminations helped distinguish true workforce risk from simple headcount scale.
- **Termination type matters for interpretation:** splitting exits into **Voluntary**, **Involuntary**, **Other**, and potential data-quality edge cases made the attrition view more actionable than a single rolled-up measure.
- **Department and tenure both change the story:** overall attrition can look stable while specific tenure bands or departments carry a disproportionate share of exits, making filterable driver analysis more useful than a single summary chart.
- **Workforce KPIs are highly sensitive to time logic:** headcount and attrition metrics only behaved correctly once the dashboard consistently anchored calculations to the latest visible month rather than mixing values across periods.
- **Recruiting performance is a balance of speed and quality:** source channels should not be judged only by applicant volume; acceptance rate, progression through the funnel, and hiring outcomes provide a more complete picture.
- **Top-line funnel counts can be misleading without stage definitions:** recruiting metrics became much more reliable after standardizing stage names, outcomes, and status logic across candidate and stage-event data.
- **Chronology issues can quietly distort hiring metrics:** invalid requisition close dates would have polluted time-to-fill results, so quarantining bad dates in the clean layer protected downstream analysis without altering raw data.
- **Dashboard filters can easily break KPI meaning:** a major part of the build was making sure KPIs, titles, and charts responded to year, quarter, region, and month logic in a consistent way instead of showing partial or misleading totals.

## Key build decisions
- **Built as a Tableau dashboard on top of Databricks SQL outputs:** Databricks handled ingestion, cleaning, validation, and mart-style query preparation, while Tableau was used for the final visuals.
- **Structured the dataset as a multi-table HR/TA model:** used separate dimensions and fact tables to support workforce and recruiting analysis without relying on messy fact-to-fact dashboard joins.
- **Standardized messy source values in the clean layer:** normalized casing, label variants, blank/`"NULL"` values, and mixed date formats before building metrics.
- **Protected time-to-fill metrics with chronology handling:** requisitions with invalid `closed_date < opened_date` were handled in the clean layer by nulling invalid close dates rather than modifying raw records.
- **Used helper fields to make dashboard logic stable:** created fields such as `is_active_flag`, `tenure_band`, `is_open_flag`, `time_to_fill_days`, and stage-based helpers so Tableau visuals could rely on prepared logic instead of fragile front-end calculations alone.
- **Designed KPI logic around the latest visible month:** this helped workforce KPIs respond correctly to filters and avoided mixing values from different months in summary tiles.
- **Separated workforce health from recruiting funnel analysis:** the dashboard was intentionally split into two pages so employee trends and recruiting performance could each answer a focused set of stakeholder questions.
- **Validated relationships before dashboarding:** checked fact-to-dimension coverage, candidate-to-requisition linkage, and stage-event-to-candidate linkage before visual design so dashboard issues would not be mistaken for data model issues.

## Artifacts
- **Project build notes (PDF):** `docs/HR_Analytics_Project_Build_Notes.pdf`
- Dashboard screenshots: `docs/screenshots/`
- **SQL used for ingestion, cleaning, validation, and dashboard prep:** [`sql/`](sql/)

## Tech stack
- Databricks SQL
- Tableau
- Curated mart schema: `workspace.hr_analytics`

## Data notes
This project uses a synthetic HR and Talent Acquisition dataset representing a mid-sized company. Raw data is not included in this repository.
I do not publish client or employer datasets. Additional sample projects using anonymized and synthetic data are in progress.
