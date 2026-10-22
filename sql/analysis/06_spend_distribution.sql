-- Question 6: how is spend spread out? Do most people spend nothing? Do a few big buyers drive the average?
WITH all_customers_by_arm AS (
	SELECT
		arm,
		COUNT(*) 															AS customers,
		ROUND(100.0 * COUNT(CASE WHEN spend = 0 THEN 1 END) / COUNT(*), 2) 	AS pct_zero_spend
	FROM marts.customer_outcomes
	GROUP BY arm
),
all_buyers_by_arm AS (
	SELECT 
		arm,
		COUNT(*) FILTER (WHERE conversion = 1) 												AS buyers,
		MIN(spend) FILTER (WHERE conversion = 1) 											AS min_spend,
		PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY spend) FILTER (WHERE conversion = 1) 	AS p25_spend,
		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY spend) FILTER (WHERE conversion = 1) 	AS median_spend,
		PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY spend) FILTER (WHERE conversion = 1)	AS p75_spend,
		PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY spend) FILTER (WHERE conversion = 1) 	AS p90_spend,
		MAX(spend) FILTER (WHERE conversion = 1) 											AS max_spend,
		ROUND(AVG(spend) FILTER (WHERE conversion = 1), 2) 									AS avg_spend,
		COUNT(CASE WHEN spend = 29.99 THEN 1 END) 											AS buyers_at_min,
		COUNT(CASE WHEN spend = 499.00 THEN 1 END) 											AS buyers_at_max
	FROM marts.customer_outcomes
	GROUP BY arm
)
SELECT
	b.arm,
	c.customers,
	c.pct_zero_spend,
	b.buyers,
	b.min_spend,
	b.p25_spend,
	b.median_spend,
	b.p75_spend,
	b.p90_spend,
	b.max_spend,
	b.avg_spend,
	b.buyers_at_min,
	b.buyers_at_max
FROM all_buyers_by_arm b
JOIN all_customers_by_arm c ON b.arm = c.arm
ORDER BY CASE b.arm WHEN 'control' THEN 1 WHEN 'mens' THEN 2 ELSE 3 END; 
-- Result (2026-10-21):
-- 1. Most customers spent nothing: 99.43% in control, 98.75% in mens,
--    99.12% in womens. Spend is mostly $0 with a long tail, not bell-shaped,
--    so the spend lift will be tested with the bootstrap and checked with a t-test.
-- 2. Among buyers, the median is lower than the average in every arm
--    (mens: $66.98 vs $113.53). A few big buyers pull the average up.
-- 3. The $499 cap affects all arms about the same (about 2% of buyers).
--    The $29.99 minimum affects mens more: 26% of mens buyers spent exactly
--    $29.99, vs 21% in control and womens. The Mens email brought in more
--    small purchases, which is why its median is the lowest.