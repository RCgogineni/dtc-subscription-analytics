-- ============================================================
-- 01_staging.sql
-- Cleans and types the raw loaded tables. Run in DTC_SUBSCRIPTION_ANALYTICS.
-- ============================================================

USE DATABASE DTC_SUBSCRIPTION_ANALYTICS;
USE SCHEMA STAGING;

CREATE OR REPLACE VIEW STG_CUSTOMERS AS
SELECT
    customer_id,
    CAST(signup_date AS DATE)                      AS signup_date,
    DATE_TRUNC('month', CAST(signup_date AS DATE)) AS signup_month,
    acquisition_channel,
    plan_type,
    skin_segment,
    country,
    age,
    gender,
    CAST(monthly_price AS NUMBER(10,2))            AS monthly_price,
    CAST(is_churned AS BOOLEAN)                    AS is_churned,
    CAST(cancellation_date AS DATE)                AS cancellation_date
FROM RAW.CUSTOMERS_RAW;

CREATE OR REPLACE VIEW STG_BILLING_TRANSACTIONS AS
SELECT
    transaction_id,
    customer_id,
    CAST(billing_date AS DATE)                      AS billing_date,
    DATE_TRUNC('month', CAST(billing_date AS DATE)) AS billing_month,
    transaction_type,
    plan_type_at_transaction,
    CAST(amount AS NUMBER(10,2))                    AS amount
FROM RAW.BILLING_TRANSACTIONS_RAW;

-- sanity checks
SELECT COUNT(*) AS customer_count FROM STG_CUSTOMERS;
SELECT COUNT(*) AS txn_count FROM STG_BILLING_TRANSACTIONS;
SELECT MIN(signup_date), MAX(signup_date) FROM STG_CUSTOMERS;
