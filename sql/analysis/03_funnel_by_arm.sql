-- Question 3: How does each arm move through the funnel:
-- customers -> visitors -> buyers -> spend?
-- Rates are in %. Spend is in $. Point estimates only; tests come in later work.
SELECT
    arm,
    COUNT(*)                                                    AS customers,
    SUM(visit)                                                  AS visitors,
    SUM(conversion)                                             AS buyers,
    ROUND(100.0 * AVG(visit), 2)                                AS visit_rate,
    ROUND(100.0 * AVG(conversion), 2)                           AS conversion_rate,
    ROUND(100.0 * SUM(conversion) / NULLIF(SUM(visit), 0), 2)   AS visit_to_buy_rate,
    SUM(spend)                                                  AS total_spend,
    ROUND(AVG(spend), 2)                                        AS spend_per_customer,
    -- NULLIF avoids a division by zero error: if the count is 0, the rate is NULL
    ROUND(SUM(spend) / NULLIF(SUM(conversion), 0), 2)           AS avg_order_value
FROM marts.customer_outcomes
GROUP BY arm
ORDER BY CASE arm WHEN 'control' THEN 1 WHEN 'mens' THEN 2 ELSE 3 END;
-- Result:
-- Mens email vs no email: visit rate 18.28% vs 10.62%, conversion 1.25% vs 0.57%.
--   Of visitors, 6.86% bought vs 5.39% in control.
-- Womens email vs no email: visit rate 15.14% vs 10.62%,
--   conversion 0.88% vs 0.57%. Both emails beat no email; Mens is higher.
-- Not concluded yet: whether these gaps are real or noise (will be tested later).
-- Average order value (Mens $113.53, Womens $121.89) is based on only ~200 buyers
--   It is too small to pick a winner, and it is a guardrail metric, not the main goal.
