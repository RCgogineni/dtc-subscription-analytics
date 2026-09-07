-- ============================================================
-- 02_customer_month_spine.sql
-- Builds a customer x calendar-month grain table: for every customer,
-- one row per month from their signup month through the observation
-- window end, flagged active/inactive. This is the foundation every
-- MRR, cohort, and LTV mart is built on top of.
-- ============================================================

USE DATABASE DTC_SUBSCRIPTION_ANALYTICS;
USE SCHEMA MARTS;

-- calendar spine: one row per month across the whole observation window
CREATE OR REPLACE TABLE DIM_MONTHS AS
SELECT DATEADD('month', SEQ4(), '2024-01-01') AS month_start
FROM TABLE(GENERATOR(ROWCOUNT => 24))  -- covers Jan 2024 - Dec 2025; widen if needed
WHERE month_start <= '2025-09-01';

CREATE OR REPLACE TABLE FACT_CUSTOMER_MONTHLY AS
SELECT
    c.customer_id,
    c.signup_month,
    c.acquisition_channel,
    c.plan_type,
    c.skin_segment,
    c.country,
    m.month_start,
    DATEDIFF('month', c.signup_month, m.month_start) AS months_since_signup,
    CASE
        WHEN m.month_start >= c.signup_month
         AND (c.cancellation_date IS NULL OR m.month_start < DATE_TRUNC('month', c.cancellation_date))
        THEN TRUE ELSE FALSE
    END AS is_active,
    CASE
        WHEN m.month_start >= c.signup_month
         AND (c.cancellation_date IS NULL OR m.month_start < DATE_TRUNC('month', c.cancellation_date))
        THEN c.monthly_price ELSE 0
    END AS mrr
FROM STAGING.STG_CUSTOMERS c
CROSS JOIN DIM_MONTHS m
WHERE m.month_start >= c.signup_month;  -- no rows before a customer existed

-- sanity check: active customers per month should never exceed cumulative signups
SELECT month_start, COUNT_IF(is_active) AS active_customers, SUM(mrr) AS total_mrr
FROM FACT_CUSTOMER_MONTHLY
GROUP BY month_start
ORDER BY month_start;
