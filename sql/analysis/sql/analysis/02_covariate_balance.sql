-- Question 2: Do the three arms have similar customers before the experiment?
-- (Balance check: if randomisation worked, all features should be close)
SELECT 
	arm,
	ROUND(AVG(recency), 2) AS avg_recency,
	ROUND(AVG(history), 2) AS avg_history,
	ROUND(100.0 * COUNT(CASE WHEN newbie = 1 THEN 1 END) /  COUNT(*), 2) 				AS newbie_pct,
	ROUND(100.0 * COUNT(CASE WHEN channel = 'Web' THEN 1 END) / COUNT(*), 2) 			AS web_channel_pct,
	ROUND(100.0 * COUNT(CASE WHEN channel = 'Phone' THEN 1 END) / COUNT(*), 2) 			AS phone_channel_pct,
	ROUND(100.0 * COUNT(CASE WHEN channel = 'Multichannel' THEN 1 END) / COUNT(*), 2) 	AS multi_channel_pct,
	ROUND(100.0 * COUNT(CASE WHEN zip_code = 'Suburban' THEN 1 END) / COUNT(*), 2) 		AS suburban_pct,
	ROUND(100.0 * COUNT(CASE WHEN zip_code = 'Urban' THEN 1 END) / COUNT(*), 2)		 	AS urban_pct,
	ROUND(100.0 * COUNT(CASE WHEN zip_code = 'Rural' THEN 1 END) / COUNT(*), 2) 		AS rural_pct,
	ROUND(100.0 * COUNT(CASE WHEN mens = 1 THEN 1 END) / COUNT(*), 2) 					AS mens_purchase_pct,
	ROUND(100.0 * COUNT(CASE WHEN womens = 1 THEN 1 END) / COUNT(*), 2) 				AS womens_purchase_pct
FROM marts.customer_outcomes
GROUP BY arm
ORDER BY CASE arm WHEN 'control' THEN 1 WHEN 'mens' THEN 2 ELSE 3 END;
-- Result: the arms are balanced.
-- The largest gap is phone channel: 44.20% in womens vs 43.37% in mens,
-- a difference of 0.83 percentage points. Web channel is close (0.80 pp).
-- All other percentage gaps are below 0.6 pp.
-- Average history differs by less than $2 (240.88 vs 242.84), under 1%.
-- Average recency is almost the same in all arms (5.75 vs 5.77 months).
-- So the random split worked, and differences between arms in the results
-- can be explained by the emails, not by different customers.