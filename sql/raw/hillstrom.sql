-- Raw layer: one row per line of the source CSV, no changes.
-- Rebuilt from scratch on every load, so the pipeline can be rerun safely.

DROP TABLE IF EXISTS raw.hillstrom CASCADE;

CREATE TABLE raw.hillstrom (
    recency          SMALLINT,
    history_segment  TEXT,
    history          NUMERIC(10, 2),
    mens             SMALLINT,
    womens           SMALLINT,
    zip_code         TEXT,
    newbie           SMALLINT,
    channel          TEXT,
    segment          TEXT,
    visit            SMALLINT,
    conversion       SMALLINT,
    spend            NUMERIC(10, 2)
);
