-- Question 4: How much does each email improve visits, conversion and spend compared with no email (control)?
-- Absolute lift = arm minus control (percentage points, or $ for spend).
-- Relative lift = absolute lift divided by control (%).
-- Point estimates only. Whether the lifts are real or noise is tested in Phase 5.
WITH rates_per_arm AS (
	SELECT
		arm,
		100.0 * SUM(visit) / COUNT(*) AS visit_rate,
		100.0 * AVG(conversion)       AS conversion_rate,
		AVG(spend)                    AS spend_per_customer
	FROM marts.customer_outcomes
	GROUP BY arm
),
control_values_added AS (
	SELECT
		arm,
		visit_rate,
		MAX(CASE WHEN arm = 'control' THEN visit_rate END) OVER () 			AS control_visit_rate,
		conversion_rate,
		MAX(CASE WHEN arm = 'control' THEN conversion_rate END) OVER () 	AS control_conv_rate,
		spend_per_customer,
		MAX(CASE WHEN arm = 'control' THEN spend_per_customer END) OVER () 	AS control_spend_per_customer
	FROM rates_per_arm
)
SELECT 
	arm,
	ROUND(visit_rate, 2) 														AS visit_rate,
	ROUND(control_visit_rate, 2)												AS control_visit_rate,
	ROUND(visit_rate - control_visit_rate, 2)		 							AS visit_rate_absolute_lift_pp,
	ROUND((visit_rate - control_visit_rate) / control_visit_rate * 100.0, 2) 	AS visit_rate_relative_lift_pct,
	ROUND(conversion_rate, 2) 													AS conversion_rate,
	ROUND(control_conv_rate, 2) 												AS control_conversion_rate,
	ROUND(conversion_rate - control_conv_rate, 2)		 						AS conversion_rate_absolute_lift_pp,
	ROUND((conversion_rate - control_conv_rate) / control_conv_rate * 100.0, 2) AS conversion_rate_relative_lift_pct,
	ROUND(spend_per_customer, 2) 												AS spend_per_customer,
	ROUND(control_spend_per_customer, 2)										AS control_spend_per_customer,
	ROUND(spend_per_customer - control_spend_per_customer, 2)		 									AS spend_absolute_lift_usd,
	ROUND((spend_per_customer - control_spend_per_customer) / control_spend_per_customer * 100.0, 2) 	AS spend_relative_lift_pct	
FROM control_values_added 
WHERE arm IN ('womens', 'mens')
ORDER BY arm;
-- Result:
-- Mens email vs no email: conversion +0.68 pp (0.57% -> 1.25%, +119%),
--   spend +$0.77 per customer (+118%).
--   That is about +$770 revenue per 1,000 emails (calculated: $0.77 x 1,000).
-- Womens email vs no email: conversion +0.31 pp (0.57% -> 0.88%, +54%),
--   spend +$0.42 per customer (+65%).
--   That is about +$420 revenue per 1,000 emails (calculated: $0.42 x 1,000).
-- Mens is stronger than Womens on all three metrics.
-- My plan set +0.3 pp conversion as the minimum useful effect.
--   Mens is clearly above it; Womens is just at the line (+0.31 pp).
-- Phase 5 must test if these lifts are real, and especially if the Womens
--   lift is above +0.3 pp or could be smaller.