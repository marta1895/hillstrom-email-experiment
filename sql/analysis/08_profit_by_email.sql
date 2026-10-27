-- Question 8: If we send one email to all 64,000 customers, how much extra profit does each email bring compared with sending nothing?
-- Results are point estimates based on the average extra spend per customer.
-- The data has no costs, so I made conservative assumptions: $0.01 per email, rounded up from typical sending costs, and a 40% margin, the low end for clothing retail. 
WITH assumptions AS (
    SELECT
        0.01   AS cost_per_email,   -- my assumption, not data
        0.40   AS margin,           -- my assumption, not data
        64000  AS emails_sent       -- send to all customers
),
spend_per_arm AS (
    SELECT
        arm,
        AVG(spend) AS spend_per_customer
    FROM marts.customer_outcomes
    GROUP BY arm
),
extra_spend AS (
    -- extra spend per customer = email arm minus control (not rounded yet)
    SELECT
        arm,
        spend_per_customer
          - MAX(CASE WHEN arm = 'control' THEN spend_per_customer END) OVER ()
          AS extra_spend_per_customer
    FROM spend_per_arm
),
money AS (
    -- money for sending one email to all customers
    SELECT
        e.arm,
        e.extra_spend_per_customer,
        e.extra_spend_per_customer * a.emails_sent  AS extra_revenue,
        a.cost_per_email * a.emails_sent            AS email_cost,
        a.margin,
        a.emails_sent
    FROM extra_spend e
    CROSS JOIN assumptions a
    WHERE e.arm IN ('mens', 'womens')
)
SELECT
    arm,
    ROUND(extra_spend_per_customer, 2)                                AS extra_spend_per_customer,
    ROUND(extra_revenue, 2)                                           AS extra_revenue,
    ROUND(email_cost, 2)                                              AS email_cost,
    ROUND(extra_revenue * margin - email_cost, 2)                     AS extra_profit,
    ROUND((extra_revenue * margin - email_cost) / emails_sent * 1000, 2)  AS profit_per_1000_emails
FROM money
ORDER BY arm;
-- Result:
-- 1. The Mens email brings $19,067 extra profit, almost twice the Womens email ($10,224).
--    This supports the Mens email as the main choice.
-- 2. The Womens email is profitable on its own. Even at the lowest end of its spend range (+$0.16 per customer),
--    it earns $0.054 per customer after costs, about $3,460 for 64,000 emails.
-- 3. The Womens email loses money only if one email costs more than about $0.17 (extra spend x margin), 17 times my assumed cost.
--    Even at the lowest spend estimate, the break-even cost is about $0.06. So email cost is not a risk here.