-- ============================================================
-- 05_mart_churn_segmentation.sql
-- Churn rate cut by plan, channel, and skin segment - answers
-- "which segments are we losing, and where should retention effort go".
-- ============================================================

USE DATABASE DTC_SUBSCRIPTION_ANALYTICS;
USE SCHEMA MARTS;

CREATE OR REPLACE VIEW MART_CHURN_BY_SEGMENT AS
SELECT
    'plan_type' AS segment_type,
    plan_type   AS segment_value,
    COUNT(*)                              AS customers,
    COUNT_IF(is_churned)                  AS churned_customers,
    ROUND(COUNT_IF(is_churned) / COUNT(*) * 100, 1) AS churn_rate_pct
FROM STAGING.STG_CUSTOMERS
GROUP BY plan_type

UNION ALL

SELECT
    'acquisition_channel' AS segment_type,
    acquisition_channel   AS segment_value,
    COUNT(*)                              AS customers,
    COUNT_IF(is_churned)                  AS churned_customers,
    ROUND(COUNT_IF(is_churned) / COUNT(*) * 100, 1) AS churn_rate_pct
FROM STAGING.STG_CUSTOMERS
GROUP BY acquisition_channel

UNION ALL

SELECT
    'skin_segment' AS segment_type,
    skin_segment   AS segment_value,
    COUNT(*)                              AS customers,
    COUNT_IF(is_churned)                  AS churned_customers,
    ROUND(COUNT_IF(is_churned) / COUNT(*) * 100, 1) AS churn_rate_pct
FROM STAGING.STG_CUSTOMERS
GROUP BY skin_segment

ORDER BY segment_type, churn_rate_pct DESC;

-- rank segments within each segment_type by churn rate (window function)
CREATE OR REPLACE VIEW MART_CHURN_SEGMENT_RANKED AS
SELECT
    *,
    RANK() OVER (PARTITION BY segment_type ORDER BY churn_rate_pct DESC) AS churn_rank
FROM MART_CHURN_BY_SEGMENT;

SELECT * FROM MART_CHURN_SEGMENT_RANKED;
