-- Question 5: Does each email work equally well for every customer group, or better for some groups than others?
-- Each email arm is compared with control customers from the SAME segment.
-- Conversion in %, lifts in percentage points (pp) and %, spend in $.
-- EXPLORATORY: about 20 segments are tested, so some differences will appear by luck.
-- No segment result is treated as proven.
-- enough_customers = FALSE means fewer than 1,000 customers in the arm or in
-- control for that segment, so those numbers are not reliable.
WITH rates_per_segment AS (
	SELECT
		dimension,
		segment_value,
		value_order,
		arm,
		customers,
		MAX(CASE WHEN arm = 'control' THEN customers END) OVER (PARTITION BY dimension, segment_value) 			AS control_customers,
		conversion_rate,
		MAX(CASE WHEN arm = 'control' THEN conversion_rate END) OVER (PARTITION BY dimension, segment_value) 	AS control_conversion_rate,
		spend_per_customer,
		MAX(CASE WHEN arm = 'control' THEN spend_per_customer END) OVER (PARTITION BY dimension, segment_value) AS control_spend_per_customer
	FROM marts.segment_arm_summary
)
SELECT 
	dimension,
	segment_value,
	value_order,
	arm,
	customers,
	control_customers,
	ROUND(conversion_rate * 100.0, 2) 																AS conversion_rate,
	ROUND(control_conversion_rate * 100.0, 2) 														AS control_conversion_rate,
	ROUND((conversion_rate - control_conversion_rate)*100.0, 2)		 								AS conversion_rate_absolute_lift_pp,
	ROUND((conversion_rate - control_conversion_rate) / control_conversion_rate * 100.0, 2) AS conversion_rate_relative_lift_pct,
	ROUND(spend_per_customer, 2) 															AS spend_per_customer,
	ROUND(control_spend_per_customer, 2) 													AS control_spend_per_customer,
	ROUND(spend_per_customer - control_spend_per_customer, 2) 								AS spend_absolute_lift_usd,
	customers >= 1000 AND control_customers >= 1000  AS enough_customers
FROM rates_per_segment
WHERE arm IN ('womens', 'mens')
ORDER BY dimension, value_order, segment_value, arm;
-- Result (2026-10-20), exploratory:
-- 1. The Mens email lifts conversion in every segment, mostly +0.5 to +0.9 pp.
--    Biggest lift: customers who bought both men's and women's items (0.93% -> 2.43%, +1.50 pp).
-- 2. The Mens email also works for women's only buyers (+0.57 pp).
--    The Womens email does almost nothing for men's only buyers (+0.06 pp).
--    This explains why Mens is stronger overall.
-- 3. The Womens email shows small negative lifts in two history segments
--    ($200-350, $350-500). With ~20 segments tested, this is likely luck.
-- 4. History segments $750-1,000 and $1,000+ have under 1,000 customers per arm.
--    Their large lifts are based on very few buyers and are not reliable.