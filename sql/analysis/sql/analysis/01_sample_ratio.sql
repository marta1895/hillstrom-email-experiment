-- Question 1: Did the random split put about 1/3 of customers in each arm?
-- Expected share is 100/3 %. Differences are in percentage points.
SELECT
    arm,
    COUNT(*)                                                        AS customers,
    SUM(COUNT(*)) OVER ()                                           AS total_customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)              AS share_pct,
    ROUND(100.0 / 3, 2)                                             AS expected_pct,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () - 100.0 / 3, 2)  AS diff_pct_points
FROM marts.customer_outcomes
GROUP BY arm
ORDER BY CASE arm WHEN 'control' THEN 1 WHEN 'mens' THEN 2 ELSE 3 END;
-- Result:
-- Each arm has almost exactly 1/3 of customers: 33.29% in control and mens,
-- 33.42% in womens. The biggest difference from 1/3 is +0.08 pp (womens),
-- only 81 customers more than the smallest arm.