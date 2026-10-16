-- One row per (segment dimension, segment value, arm), in long format.
--
-- Long format means every dimension uses the same columns, so one Tableau
-- view with a "dimension" filter can show any segment, and one Python
-- function can test all of them.
--
-- CROSS JOIN LATERAL (VALUES ...) turns each customer row into one row per
-- dimension (an "unpivot"), instead of writing six GROUP BY queries joined
-- with UNION ALL.

CREATE OR REPLACE VIEW marts.segment_arm_summary AS
WITH customer_dimensions AS (
    SELECT
        c.arm,
        d.dimension,
        d.segment_value,
        d.value_order,
        c.visit,
        c.conversion,
        c.spend
    FROM staging.customers AS c
    CROSS JOIN LATERAL (
        VALUES
            ('purchase_history_type', c.purchase_history_type, 0),
            ('newbie', CASE c.newbie WHEN 1 THEN 'new' ELSE 'returning' END, c.newbie::INT),
            ('zip_code', c.zip_code, 0),
            ('channel', c.channel, 0),
            ('history_segment', c.history_segment, c.history_segment_order::INT),
            ('recency_band', c.recency_band, 0)
    ) AS d (dimension, segment_value, value_order)
)
SELECT
    dimension,
    segment_value,
    value_order,
    arm,
    COUNT(*)                                           AS customers,
    SUM(visit)                                         AS visits,
    SUM(conversion)                                    AS conversions,
    SUM(spend)                                         AS total_spend,
    ROUND(AVG(visit), 5)                               AS visit_rate,
    ROUND(AVG(conversion), 5)                          AS conversion_rate,
    ROUND(AVG(spend), 4)                               AS spend_per_customer
FROM customer_dimensions
GROUP BY dimension, segment_value, value_order, arm;
