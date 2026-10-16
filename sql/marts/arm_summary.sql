-- One row per experiment arm: counts, totals and rates.
-- Point estimates only. Confidence intervals and tests are done in Python.

CREATE OR REPLACE VIEW marts.arm_summary AS
SELECT
    arm,
    CASE arm WHEN 'control' THEN 1 WHEN 'mens' THEN 2 ELSE 3 END  AS arm_order,
    COUNT(*)                                                      AS customers,
    SUM(visit)                                                    AS visits,
    SUM(conversion)                                               AS conversions,
    SUM(spend)                                                    AS total_spend,
    ROUND(AVG(visit), 5)                                          AS visit_rate,
    ROUND(AVG(conversion), 5)                                     AS conversion_rate,
    ROUND(AVG(spend), 4)                                          AS spend_per_customer,
    -- average order value among buyers only; NULLIF avoids division by zero
    ROUND(SUM(spend) / NULLIF(SUM(conversion), 0), 2)             AS avg_order_value
FROM staging.customers
GROUP BY arm;
