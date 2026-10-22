-- Question 7: What is unusual in the data, and how many rows does each issue affect?
-- Each row is one check. expected = '0' means a rule that must never break;
-- expected = 'info' means a known feature of the data, counted for the record.
-- pct_of_customers is the share of all 64K customers, not of buyers.
WITH checks AS (
	SELECT 
		'Fully identical rows' 															AS check_name, 
		COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM raw.hillstrom) AS d) 	AS rows_affected,
	    'info' 																			AS expected
	FROM raw.hillstrom
	
	UNION ALL
	
	SELECT 
		'zip_code = Surburban in raw' 				AS check_name, 
		COUNT(CASE WHEN zip_code = 'Surburban' THEN 1 END) 	AS rows_affected,
		'info' 												AS expected
	FROM raw.hillstrom
	
	UNION ALL
	
	SELECT 
		'zip_code = Surburban after cleaning' 		AS check_name, 
		COUNT(CASE WHEN zip_code = 'Surburban' THEN 1 END) 	AS rows_affected, 
		'0' 												AS expected
	FROM staging.customers
	
	UNION ALL
	
	SELECT 
		'Experiment buyers with spend exactly $29.99' 		AS check_name, 
		COUNT(CASE WHEN spend = 29.99 THEN 1 END) 			AS rows_affected, 
		'info' 												AS expected
	FROM marts.customer_outcomes
	
	UNION ALL
	
	SELECT 
		'Experiment buyers with spend exactly $499.00' 		AS check_name, 
		COUNT(CASE WHEN spend = 499.00 THEN 1 END) 			AS rows_affected, 
		'info' 												AS expected
	FROM marts.customer_outcomes
	
	UNION ALL
	
	SELECT 
		'Customers with past-year history exactly $29.99' 	AS check_name, 
		COUNT(CASE WHEN history = 29.99 THEN 1 END) 		AS rows_affected, 
		'info' 												AS expected
	FROM marts.customer_outcomes
	
	UNION ALL
	
	SELECT 
		'Bought without visiting' 							AS check_name, 
		COUNT(*) 											AS rows_affected, 
		'0' 												AS expected
	FROM marts.customer_outcomes
	WHERE conversion = 1 AND visit = 0
	
	UNION ALL
	
	SELECT 
		'Spend without a purchase' 							AS check_name, 
		COUNT(*) 											AS rows_affected, 
		'0' 												AS expected
	FROM marts.customer_outcomes
	WHERE spend > 0 AND conversion = 0
	
	UNION ALL
	
	SELECT 
		'No mens or womens purchase history' 				AS check_name, 
		COUNT(*) 											AS rows_affected, 
		'0' 												AS expected
	FROM marts.customer_outcomes
	WHERE mens = 0 AND womens = 0
)
SELECT
    check_name,
    rows_affected,
    ROUND(100.0 * rows_affected / (SELECT COUNT(*) FROM marts.customer_outcomes), 2)  AS pct_of_customers,
    expected
FROM checks;
-- Result:
-- All rules that must never break pass: 0 customers bought without visiting,
-- 0 spent without a purchase, 0 have no purchase history, and no "Surburban" is left after cleaning.
-- Known features of the data are confirmed:
-- - 6,562 fully identical rows (10.25%). There is no customer ID, so they are kept.
-- - "Surburban" is misspelled in 28,776 raw rows (44.96%); fixed in cleaning.
-- - 136 buyers spent exactly $29.99 and 12 spent exactly $499: spend is cut at both ends.
-- - 7,947 customers (12.42%) have a past-year history of exactly $29.99.
--   The same minimum appears in two columns, so the provider cut small values at $29.99.