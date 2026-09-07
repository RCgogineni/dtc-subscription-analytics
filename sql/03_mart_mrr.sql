-- ============================================================
-- 03_mart_mrr.sql
-- Monthly MRR trend + a new-vs-churned MRR waterfall, built with
-- window functions (LAG) over the customer-month spine.
-- ============================================================

USE DATABASE DTC_SUBSCRIPTION_ANALYTICS;
USE SCHEMA MARTS;

CREATE OR REPLACE VIEW MART_CUSTOMER_MONTHLY_STATUS AS
SELECT
    customer_id,
    month_start,
    is_active,
    mrr,
    acquisition_channel,
    plan_type,
    skin_segment,
    LAG(is_active) OVER (PARTITION BY customer_id ORDER BY month_start) AS was_active_prior_month,
    LAG(mrr)       OVER (PARTITION BY customer_id ORDER BY month_start) AS mrr_prior_month
FROM FACT_CUSTOMER_MONTHLY;

CREATE OR REPLACE VIEW MART_MRR_MONTHLY AS
SELECT
    month_start,
    SUM(mrr)                                                       AS total_mrr,
    LAG(SUM(mrr)) OVER (ORDER BY month_start)                      AS prior_month_mrr,
    SUM(mrr) - LAG(SUM(mrr)) OVER (ORDER BY month_start)           AS mrr_change,
    SUM(CASE WHEN is_active AND (was_active_prior_month IS NULL OR was_active_prior_month = FALSE)
             THEN mrr ELSE 0 END)                                  AS new_mrr,
    SUM(CASE WHEN NOT is_active AND was_active_prior_month = TRUE
             THEN mrr_prior_month ELSE 0 END) * -1                 AS churned_mrr,
    COUNT_IF(is_active)                                            AS active_customers
FROM MART_CUSTOMER_MONTHLY_STATUS
GROUP BY month_start
ORDER BY month_start;

-- MRR by segment cut, for the Tableau dashboard
CREATE OR REPLACE VIEW MART_MRR_BY_CHANNEL AS
SELECT month_start, acquisition_channel, SUM(mrr) AS mrr
FROM FACT_CUSTOMER_MONTHLY
WHERE is_active
GROUP BY month_start, acquisition_channel
ORDER BY month_start, acquisition_channel;

CREATE OR REPLACE VIEW MART_MRR_BY_PLAN AS
SELECT month_start, plan_type, SUM(mrr) AS mrr
FROM FACT_CUSTOMER_MONTHLY
WHERE is_active
GROUP BY month_start, plan_type
ORDER BY month_start, plan_type;

SELECT * FROM MART_MRR_MONTHLY;
