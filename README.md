# DTC Subscription Analytics

A Snowflake + Tableau analytics project modeling subscriber retention, churn, and lifetime value for a direct-to-consumer (DTC) subscription business.

**[View the live dashboard on Tableau Public →](https://public.tableau.com/app/profile/reshma.gogineni/viz/DTCSubscriptionAnalytics/DTCSubscriptionAnalytics)**

---

## Overview

This project analyzes subscriber behavior across four areas that map directly to how a real subscription analytics team monitors the business:

- **Monetization** — Monthly Recurring Revenue (MRR) trend, decomposed into new vs. churned revenue
- **Retention** — cohort-based retention curves (what % of each signup-month cohort is still active N months later)
- **Churn** — churn rate segmented by plan type, acquisition channel, and product segment
- **Lifetime Value (LTV)** — average customer value by plan and acquisition channel

Built end-to-end: synthetic data generation → Snowflake data modeling (staging → analytics marts) → SQL analysis using window functions → a 5-panel Tableau dashboard.

## Tech Stack

- **Python** (pandas) — synthetic dataset generation
- **Snowflake** — data warehouse, SQL modeling
- **SQL** — window functions (`LAG`, `RANK`, `SUM() OVER`), CTEs, date-spine pattern
- **Tableau** — dashboard and visualization

## Repository Structure

```
├── sql/
│   ├── 01_staging.sql                  # Clean/type raw tables
│   ├── 02_customer_month_spine.sql     # Customer x month grain fact table
│   ├── 03_mart_mrr.sql                 # MRR trend + new/churned decomposition
│   ├── 04_mart_cohort_retention.sql    # Cohort retention curves
│   ├── 05_mart_churn_segmentation.sql  # Churn rate by segment
│   ├── 06_mart_ltv.sql                 # Customer lifetime value
│   └── sanity_checks.sql               # Validation queries
├── data-generation/
│   └── generate_data.py                # Synthetic dataset generator
├── docs/
│   └── methodology_and_findings_memo.md
└── README.md
```

## Key Findings

*(Based on the generated dataset — see [data note](#data-note) below)*

- **Plan type is the strongest churn lever**: Annual subscribers churn at 4.6% vs. 49.1% for Monthly, and carry ~$385 average LTV vs. ~$218
- **Referral is the standout acquisition channel**: lowest churn (26.0%) and highest LTV (~$275) of any channel
- **Retention follows a classic early-churn curve**: steepest drop-off in the first 1–3 months post-signup, then leveling off

Full findings, methodology, and disclosed assumptions/limitations are in [`docs/methodology_and_findings_memo.md`](docs/methodology_and_findings_memo.md).

## Data Note

The dataset is **synthetically generated**, built to combine realistic DTC subscription business dynamics with genuine signup/billing dates — a combination not available in public datasets at the time this project was built (real datasets either had DTC business context with no dates, or dates with a non-DTC business model). The generation logic, business rules, and full limitations are documented in the methodology memo. The analytical methods (SQL modeling, window functions, cohort logic, dashboard design) are fully representative of real-world analytics work; the specific findings describe patterns in the generated data, not a real company's results.

## Skills Demonstrated

- SQL window functions for time-series and cohort analysis (`LAG`, `RANK`, running totals)
- Data warehouse modeling (staging → marts pattern)
- Cohort retention analysis
- Subscription business metrics (MRR, churn, LTV)
- Dashboard design for a non-technical audience
- Documented methodology, assumptions, and known limitations
