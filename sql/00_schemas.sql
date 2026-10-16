-- Three layers, each in its own schema:
--   raw     : the source file exactly as downloaded (for lineage and audit)
--   staging : cleaned and enriched data from pipeline/transform.py
--   marts   : views built for analysis and Tableau

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS marts;
