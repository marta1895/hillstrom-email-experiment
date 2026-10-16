-- Staging layer: one row per customer, loaded from data/processed/customers.csv.
--
-- The constraints repeat the most important validation rules on purpose.
-- validate.py checks the file; these constraints make the database itself
-- refuse bad rows, even if someone loads data without running the pipeline.

DROP TABLE IF EXISTS staging.customers CASCADE;

CREATE TABLE staging.customers (
    customer_id            INTEGER        PRIMARY KEY,
    recency                SMALLINT       NOT NULL CHECK (recency BETWEEN 1 AND 12),
    history_segment        TEXT           NOT NULL,
    history                NUMERIC(10, 2) NOT NULL CHECK (history > 0),
    mens                   SMALLINT       NOT NULL CHECK (mens IN (0, 1)),
    womens                 SMALLINT       NOT NULL CHECK (womens IN (0, 1)),
    zip_code               TEXT           NOT NULL CHECK (zip_code IN ('Urban', 'Suburban', 'Rural')),
    newbie                 SMALLINT       NOT NULL CHECK (newbie IN (0, 1)),
    channel                TEXT           NOT NULL CHECK (channel IN ('Web', 'Phone', 'Multichannel')),
    segment                TEXT           NOT NULL,
    visit                  SMALLINT       NOT NULL CHECK (visit IN (0, 1)),
    conversion             SMALLINT       NOT NULL CHECK (conversion IN (0, 1)),
    spend                  NUMERIC(10, 2) NOT NULL CHECK (spend >= 0),
    arm                    TEXT           NOT NULL CHECK (arm IN ('control', 'mens', 'womens')),
    is_treated             SMALLINT       NOT NULL CHECK (is_treated IN (0, 1)),
    purchase_history_type  TEXT           NOT NULL,
    recency_band           TEXT           NOT NULL,
    history_segment_order  SMALLINT       NOT NULL CHECK (history_segment_order BETWEEN 1 AND 7),

    -- Business rules across columns
    CONSTRAINT conversion_requires_visit CHECK (conversion <= visit),
    CONSTRAINT spend_matches_conversion  CHECK ((spend > 0) = (conversion = 1))
);
