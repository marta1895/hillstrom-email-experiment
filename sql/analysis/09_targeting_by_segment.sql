-- Question 9: Should each customer group get a different email, or is sending the Mens email to everyone good enough?
-- Groups: purchase history (mens_only, womens_only, both).
-- Cost per email ($0.01) and margin (40%) are assumptions, not data.
WITH assumptions AS (
    SELECT
        0.01   AS cost_per_email,   -- my assumption, not data
        0.40   AS margin,           -- my assumption, not data
        64000  AS emails_sent       -- send to all customers
),
spend_by_segemnt AS (
	SELECT
	    segment_value,
	    SUM(customers)                                                AS customers,  -- all 3 arms
	    MAX(CASE WHEN arm = 'control' THEN spend_per_customer END)    AS control_spend,
	    MAX(CASE WHEN arm = 'mens'    THEN spend_per_customer END)    AS mens_spend,
	    MAX(CASE WHEN arm = 'womens'  THEN spend_per_customer END)    AS womens_spend
	FROM marts.segment_arm_summary
	WHERE dimension = 'purchase_history_type'
	GROUP BY segment_value
),
arm_profit_per_customer AS (
	SELECT
		segment_value,
		customers,
		(mens_spend - control_spend) * margin - cost_per_email AS mens_profit_per_customer,
		(womens_spend - control_spend) * margin - cost_per_email AS womens_profit_per_customer
	FROM spend_by_segemnt
	CROSS JOIN assumptions
),
best_email_by_segment AS (
    SELECT
        segment_value,
        customers,
        mens_profit_per_customer,
        womens_profit_per_customer,
        CASE
            WHEN mens_profit_per_customer <= 0 AND womens_profit_per_customer <= 0 THEN 'none'
            WHEN mens_profit_per_customer >= womens_profit_per_customer           THEN 'mens'
            ELSE 'womens'
        END                                                                         AS best_email,
        mens_profit_per_customer * customers                                        AS profit_mens_to_all,
        -- profit of the best choice: the higher of the two, or 0 if we send nothing
        GREATEST(mens_profit_per_customer, womens_profit_per_customer, 0) * customers AS profit_targeted
    FROM arm_profit_per_customer
)
SELECT
    segment_value,
    customers,
    ROUND(mens_profit_per_customer, 3)    AS mens_profit_per_customer,
    ROUND(womens_profit_per_customer, 3)  AS womens_profit_per_customer,
    best_email,
    ROUND(profit_mens_to_all, 2)          AS profit_mens_to_all,
    ROUND(profit_targeted, 2)             AS profit_targeted
FROM best_email_by_segment
UNION ALL
SELECT 'TOTAL', SUM(customers), NULL, NULL, NULL, 
ROUND(SUM(profit_mens_to_all), 2), ROUND(SUM(profit_targeted), 2)
FROM best_email_by_segment;
-- Result:
-- The Mens email is the best choice for "both" and "mens_only" customers.
-- For "womens_only", the Womens email wins by less than one cent per customer ($0.243 vs $0.236). 
-- That is too small to trust (segment results are exploratory).
-- Targeting earns $19,197 vs $19,014 for "Mens email to everyone": only $183 more (about 1%).
-- Recommendation: send the Mens email to everyone. Sending two different emails adds work for almost no extra profit.