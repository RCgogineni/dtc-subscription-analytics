-- ============================================================
-- 06_mart_ltv.sql
-- Customer lifetime value: running revenue total per customer
-- (window function), then averaged by cohort, channel, and plan.
-- ============================================================

USE DATABASE DTC_SUBSCRIPTION_ANALYTICS;
USE SCHEMA MARTS;

-- running cumulative revenue per customer, in billing-event order
CREATE OR REPLACE VIEW MART_CUSTOMER_REVENUE_RUNNING AS
SELECT
    t.customer_id,
    t.billing_date,
    t.amount,
    SUM(t.amount) OVER (
        PARTITION BY t.customer_id ORDER BY t.billing_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue
FROM STAGING.STG_BILLING_TRANSACTIONS t
WHERE t.transaction_type = 'charge';

-- total revenue to date per customer (this IS their LTV as observed so far)
CREATE OR REPLACE VIEW MART_CUSTOMER_LTV AS
SELECT
    c.customer_id,
    c.signup_month,
    c.acquisition_channel,
    c.plan_type,
    c.skin_segment,
    c.is_churned,
    COALESCE(SUM(t.amount), 0) AS lifetime_revenue
FROM STAGING.STG_CUSTOMERS c
LEFT JOIN STAGING.STG_BILLING_TRANSACTIONS t
    ON t.customer_id = c.customer_id AND t.transaction_type = 'charge'
GROUP BY c.customer_id, c.signup_month, c.acquisition_channel, c.plan_type, c.skin_segment, c.is_churned;

-- average LTV by acquisition channel and plan (for the dashboard)
CREATE OR REPLACE VIEW MART_LTV_BY_CHANNEL AS
SELECT acquisition_channel, ROUND(AVG(lifetime_revenue), 2) AS avg_ltv, COUNT(*) AS customers
FROM MART_CUSTOMER_LTV
GROUP BY acquisition_channel
ORDER BY avg_ltv DESC;

CREATE OR REPLACE VIEW MART_LTV_BY_PLAN AS
SELECT plan_type, ROUND(AVG(lifetime_revenue), 2) AS avg_ltv, COUNT(*) AS customers
FROM MART_CUSTOMER_LTV
GROUP BY plan_type
ORDER BY avg_ltv DESC;

-- average LTV by signup cohort (do earlier cohorts have more accumulated value, as expected?)
CREATE OR REPLACE VIEW MART_LTV_BY_COHORT AS
SELECT signup_month, ROUND(AVG(lifetime_revenue), 2) AS avg_ltv, COUNT(*) AS customers
FROM MART_CUSTOMER_LTV
GROUP BY signup_month
ORDER BY signup_month;

SELECT * FROM MART_LTV_BY_CHANNEL;
SELECT * FROM MART_LTV_BY_PLAN;
