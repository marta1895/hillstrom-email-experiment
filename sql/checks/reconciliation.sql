-- Reconciliation: every layer must hold the same customers and the same money.
-- If any row here differs from raw.hillstrom, a step lost or duplicated data.
-- Each segment dimension must also add up to all customers, otherwise a
-- customer fell into no segment or into two.

SELECT 'raw.hillstrom' AS check_name, COUNT(*) AS row_count, SUM(spend) AS total_spend
FROM raw.hillstrom

UNION ALL
SELECT 'staging.customers', COUNT(*), SUM(spend)
FROM staging.customers

UNION ALL
SELECT 'marts.customer_outcomes', COUNT(*), SUM(spend)
FROM marts.customer_outcomes

UNION ALL
SELECT 'marts.arm_summary', SUM(customers), SUM(total_spend)
FROM marts.arm_summary

UNION ALL
SELECT 'marts.segment_arm_summary: ' || dimension, SUM(customers), SUM(total_spend)
FROM marts.segment_arm_summary
GROUP BY dimension;
