-- One row per customer with every feature, the arm and the outcomes.
-- Main data source for Tableau and for the Python experiment analysis.

CREATE OR REPLACE VIEW marts.customer_outcomes AS
SELECT
    customer_id,
    arm,
    is_treated,
    segment,
    -- pre-experiment features
    recency,
    recency_band,
    history,
    history_segment,
    history_segment_order,
    mens,
    womens,
    purchase_history_type,
    zip_code,
    newbie,
    channel,
    -- outcomes (two weeks after the send)
    visit,
    conversion,
    spend
FROM staging.customers;
