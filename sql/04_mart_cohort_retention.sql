-- ============================================================
-- 04_mart_cohort_retention.sql
-- True cohort retention: for each signup-month cohort, what % of
-- the original cohort is still active N months later.
-- ============================================================

USE DATABASE DTC_SUBSCRIPTION_ANALYTICS;
USE SCHEMA MARTS;

CREATE OR REPLACE VIEW MART_COHORT_RETENTION AS
WITH cohort_sizes AS (
    SELECT
        signup_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM STAGING.STG_CUSTOMERS
    GROUP BY signup_month
)
SELECT
    f.signup_month,
    f.months_since_signup,
    cs.cohort_size,
    COUNT_IF(f.is_active) AS active_customers,
    ROUND(COUNT_IF(f.is_active) / cs.cohort_size * 100, 1) AS retention_pct
FROM FACT_CUSTOMER_MONTHLY f
JOIN cohort_sizes cs ON cs.signup_month = f.signup_month
GROUP BY f.signup_month, f.months_since_signup, cs.cohort_size
ORDER BY f.signup_month, f.months_since_signup;

-- pivot-friendly version for a Tableau heatmap: cohort x months-since-signup grid
SELECT * FROM MART_COHORT_RETENTION;
