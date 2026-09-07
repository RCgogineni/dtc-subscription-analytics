# DTC Subscription Analytics — Methodology & Findings

**Project type:** Portfolio analysis, built to demonstrate skills relevant to a Senior Data Analyst role at a DTC subscription business (Curology)
**Stack:** Snowflake (SQL, window functions) → Tableau (dashboard)

---

## 1. Objective

Analyze subscriber behavior for a direct-to-consumer skincare subscription business across four dimensions that map directly to how a real subscription analytics team monitors the business:

- **Monetization** — Monthly Recurring Revenue (MRR) trend and composition
- **Retention** — cohort-based retention curves
- **Churn** — churn rate by plan type, acquisition channel, and product segment
- **Lifetime Value (LTV)** — average customer value by plan and channel

## 2. Data Source & Methodology

**The data is synthetic**, generated to mirror a realistic DTC subscription business, for the following reason: no public dataset could be found that combined (a) a DTC subscription business model and (b) real signup/billing dates, which are required for genuine cohort and MRR-trend analysis. Datasets with (a) but not (b) exist (snapshot-only, e.g. a single `tenure_months` field with no underlying dates); datasets with (b) but not (a) exist (e.g. media streaming subscriptions). Rather than force an imperfect fit, a synthetic dataset was generated with explicit, documented business rules:

- 4,200 customers, signup dates spread Jan 2024–Jun 2025 with an increasing signup rate (simulating business growth)
- Plans: Monthly, Quarterly, Annual, each with different pricing and a different underlying churn hazard (Annual plans built to churn less, reflecting real-world commitment effects)
- Acquisition channels: Paid Social, Organic Search, Influencer, Referral, Email — each with a different churn multiplier (Referral built to be the stickiest, reflecting typical DTC industry patterns)
- Skin concern segments: Acne, Anti-Aging, Hyperpigmentation
- Churn simulated via a hazard-rate model: higher cancellation probability in the first 1–3 months post-signup, tapering afterward — this mirrors the well-documented "early churn" pattern in real subscription businesses
- Observation window extends 3 months past the last signup cohort (through Sept 2025) to allow churn to play out for the most recent cohorts

This is disclosed here in full, and treated the same way undisclosed synthetic or sample data would need to be flagged in any real analytics deliverable: the analytical **methods** (SQL modeling, window functions, cohort logic, Tableau dashboarding) are the deliverable and are fully transferable; the specific **numbers** are illustrative, not real business results.

## 3. Data Modeling Approach

Standard raw → staging → marts pattern:

- **Raw**: two source tables loaded as-is — `customers` (one row per customer) and `billing_transactions` (one row per billing event or cancellation)
- **Staging**: type-cast and lightly cleaned views, no business logic
- **Marts**: business-logic layer, one mart per analytical question, built on a shared customer-month "spine" (every customer × every month since their signup, flagged active/inactive). This spine pattern is what makes true time-series MRR and cohort retention calculations possible from what is otherwise event-level data.

Window functions (`LAG`, `RANK`, `SUM() OVER`) were used throughout in place of self-joins — used to compute month-over-month MRR movement, rank segments by churn rate, and calculate running lifetime revenue per customer.

## 4. Known Limitations

- **Synthetic data**: see Section 2. Findings below describe patterns in the generated dataset, not real Curology or industry data.
- **No seasonality modeling**: signup volume grows steadily by design; real DTC businesses typically show seasonal signup spikes (e.g. New Year skincare resolutions) that this dataset does not simulate.
- **Single geography assumption**: no regional variation was built in, though the schema includes a `country` field with light distribution across US/Canada/UK.
- **Last 3 months show no new signups by design** (window ends 3 months after the last signup cohort) — any month-over-month trend reading for Jul–Sep 2025 should account for this wind-down period rather than reading it as an organic slowdown.

## 5. Key Findings

**MRR Trend**: Total MRR grew steadily from ~$3,450 (Jan 2024) to a peak of ~$85,000 (Jun 2025), consistent with the built-in signup growth curve. New MRR and Churned MRR both grew in absolute terms as the active customer base grew — expected, since a larger base produces more of both new and lost revenue even at a stable rate.

**Cohort Retention**: Retention follows the classic subscription decay curve — starting at 100% at signup and declining steadily, with the steepest drop in the first 1–3 months (by design, reflecting real-world early-churn patterns), then leveling off for longer-tenured cohorts.

**Churn by Segment**:
- By **plan type**: Annual (4.6% churn) is dramatically stickier than Monthly (49.1%) — Quarterly sits in between (32.7%)
- By **channel**: Referral (26.0%) has the lowest churn; Paid Social (43.2%) and Influencer (43.0%) the highest
- By **skin segment**: churn is relatively even across Acne, Anti-Aging, and Hyperpigmentation (37–38%) — segment-specific churn drivers were not built into this dataset, so this flat result is expected rather than a finding

**LTV**:
- By **plan**: Annual customers are worth ~$385 on average vs. ~$218 for Monthly — despite Annual being the smallest customer group by count, it is the most valuable segment per customer
- By **channel**: Referral leads at ~$275 average LTV; Influencer trails at ~$233

## 6. What This Would Suggest for a Real Business (Illustrative)

If these patterns held in a real subscription business, they would typically prompt:
- Evaluating incentives to shift Monthly subscribers toward Quarterly/Annual plans, given the retention and LTV gap
- Investing further in Referral as an acquisition channel, given its combination of lower churn and higher LTV
- Watching first-3-month retention closely as the primary lever, since that's where the steepest drop occurs

These are illustrative implications of the *pattern*, offered to demonstrate the kind of "so what" translation an analyst would do — not recommendations based on real company data.
