# HR + Talent Acquisition Analytics Dashboard (Databricks SQL + Tableau)

A 2-page analytics dashboard built with Databricks SQL and Tableau to evaluate workforce health, attrition patterns, hiring performance, and recruiting funnel quality.

## Tableau Public (Interactive)
Tableau Dashboard:
https://public.tableau.com/app/profile/cameron.scott3127/vizzes

**Note:** Tableau is currently inconsistent with direct dashboard links, so this repo references my Tableau Public vizzes homepage for access.

## Screenshots

### Page 1 — Workforce Health
![Page 1 — Workforce Health](docs/screenshots/Workforce%20Health.png)

### Page 2 — Talent Acquisition Funnel
![Page 2 — Talent Acquisition Funnel](docs/screenshots/Talent%20Acquisition%20Funnel.png)

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
- **Workforce trends require multiple metrics to interpret correctly:** headcount changes are influenced by hires, separations, promotions, and transfers, so analyzing hiring alone does not fully explain workforce stability.
- **Candidate volume does not guarantee hiring success:** some recruiting sources generate large numbers of applications but weaker downstream outcomes, demonstrating that quality of applicants matters as much as quantity.
- **Employee referrals consistently produce stronger hiring outcomes:** referral candidates tend to progress further through the hiring process and show stronger offer acceptance rates compared to many external sourcing channels.
- **The recruiting funnel exposes where candidate drop-off occurs:** the largest reductions in candidate volume occur in the mid-funnel stages, suggesting that screening criteria or candidate qualification processes significantly impact final hiring outcomes.
- **Open requisitions reveal operational hiring pressure:** departments with both a high number of open roles and older requisitions represent the greatest recruiting risk and should typically receive the highest hiring priority.
- **Hiring metrics must be standardized across datasets:** recruiting tables and workforce event tables often define hires differently, so aligning the hire definition across sources was necessary to keep dashboard KPIs consistent.

## Key build decisions
- **Pre-aggregating analytical views in SQL before visualization:** creating dashboard-ready views in Databricks simplified Tableau calculations, reduced double-counting risk, and improved dashboard performance.
- **Preserving the correct grain for workforce metrics:** workforce headcount was calculated from monthly snapshot tables rather than event data to avoid incorrectly summing point-in-time metrics across months.
- **Preventing candidate duplication in funnel analysis:** recruiting stage events were aggregated at the candidate application level to ensure each candidate appeared only once per stage, preventing inflated funnel counts.
- **Integrating regional analysis directly into the data model:** location dimensions were incorporated into analytical views so that all metrics could be consistently segmented by region without relying on complex dashboard joins.
- **Standardizing the hire definition across the analysis:** hires were treated as a canonical metric so that recruiting KPIs and workforce event metrics aligned across all visualizations.
- **Designing the dashboard as a diagnostic workflow:** the project was intentionally structured to guide users from workforce health → recruiting performance → hiring priorities, mirroring how HR teams investigate staffing challenges.

## Why this project matters
- **Hiring performance directly impacts organizational growth:** if recruiting pipelines cannot keep pace with workforce demand, departments may struggle to meet operational goals.
- **Recruiting efficiency requires more than application counts:** this project demonstrates the importance of evaluating recruiting sources based on funnel progression, offer acceptance, and hiring outcomes, not just raw applicant volume.
- **Early identification of hiring bottlenecks improves recruiting strategy:** visualizing candidate drop-off points allows HR teams to adjust sourcing, screening criteria, or interview processes.
- **Open requisition pressure highlights operational risk:** roles that remain open for extended periods can signal skill shortages, unrealistic job requirements, or limited recruiting capacity.
- **Data-driven workforce planning requires integrated metrics:** combining workforce snapshots, employee events, and recruiting pipeline data provides a more complete view of organizational health than analyzing each dataset independently.

## Artifacts
- **Project build notes (PDF):** [HR Analytics Project Build Notes](docs/HR_Analytics_Project_Build_Notes.pdf)
- Dashboard screenshots: [docs/screenshots/](docs/screenshots/)
- **SQL used for ingestion, cleaning, validation, and dashboard prep:** [sql/](sql/)

## Tech stack
- Databricks SQL
- Tableau
- Curated schema: `workspace.hr_analytics`

## Data notes
This project uses a synthetic HR and Talent Acquisition dataset representing a mid-sized company. Raw data is not included in this repository.
I do not publish client or employer datasets. Additional sample projects using anonymized and synthetic data are in progress.
