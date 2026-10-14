"""
Phase 2, step C - Transform the validated raw data.

Cleans and enriches data/raw/hillstrom.csv and writes
data/processed/customers.csv, ready to load into the database.

What it does:
- fixes the "Surburban" misspelling in zip_code
- adds a stable customer_id (the source has none)
- adds short arm codes and a treatment flag
- adds analysis fields used for segments: purchase_history_type,
  recency_band, history_segment_order

Raw data is never modified: the original file stays as downloaded.

Run from the project root (after validate passes):
    python -m pipeline.transform
"""

import logging
from pathlib import Path

import pandas as pd

RAW_FILE = Path("data/raw/hillstrom.csv")
OUTPUT_FILE = Path("data/processed/customers.csv")

ARM_CODES = {
    "Mens E-Mail": "mens",
    "Womens E-Mail": "womens",
    "No E-Mail": "control",
}

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
)
log = logging.getLogger("transform")


def purchase_history_type(mens: int, womens: int) -> str:
    if mens and womens:
        return "both"
    if mens:
        return "mens_only"
    if womens:
        return "womens_only"
    return "neither"  # validation found none, kept so nothing is silently dropped


def recency_band(months: int) -> str:
    if months <= 3:
        return "01-03 months"
    if months <= 6:
        return "04-06 months"
    if months <= 9:
        return "07-09 months"
    return "10-12 months"


def transform(raw: pd.DataFrame) -> pd.DataFrame:
    df = raw.copy()

    # Stable ID: row order of the source file, starting at 1.
    df.insert(0, "customer_id", range(1, len(df) + 1))

    # Fix the source misspelling.
    df["zip_code"] = df["zip_code"].replace({"Surburban": "Suburban"})

    # Experiment fields.
    df["arm"] = df["segment"].map(ARM_CODES)
    df["is_treated"] = (df["arm"] != "control").astype(int)

    # Segment fields.
    df["purchase_history_type"] = [
        purchase_history_type(m, w) for m, w in zip(df["mens"], df["womens"])
    ]
    df["recency_band"] = df["recency"].map(recency_band)
    # "1) $0 - $100" -> 1, so segments sort correctly in SQL and Tableau.
    df["history_segment_order"] = df["history_segment"].str[0].astype(int)

    if df["arm"].isna().any():
        raise ValueError("Unknown segment value: run validate before transform.")

    return df


def main() -> None:
    raw = pd.read_csv(RAW_FILE)
    df = transform(raw)

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(OUTPUT_FILE, index=False)

    log.info("Rows in: %d | rows out: %d", len(raw), len(df))
    log.info("Columns out: %s", ", ".join(df.columns))
    log.info("Written to %s", OUTPUT_FILE)

    if len(raw) != len(df):
        raise ValueError("Row count changed during transform.")


if __name__ == "__main__":
    main()
