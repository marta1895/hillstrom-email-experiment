"""Tests for pipeline/transform.py."""

import pandas as pd

from pipeline.transform import transform


def make_raw() -> pd.DataFrame:
    return pd.DataFrame(
        {
            "recency": [1, 5, 9, 12],
            "history_segment": ["1) $0 - $100", "2) $100 - $200", "7) $1,000 +", "3) $200 - $350"],
            "history": [50.0, 150.0, 1500.0, 300.0],
            "mens": [1, 0, 1, 1],
            "womens": [0, 1, 1, 0],
            "zip_code": ["Surburban", "Urban", "Rural", "Surburban"],
            "newbie": [0, 1, 0, 1],
            "channel": ["Web", "Phone", "Multichannel", "Web"],
            "segment": ["Mens E-Mail", "Womens E-Mail", "No E-Mail", "Mens E-Mail"],
            "visit": [0, 1, 1, 0],
            "conversion": [0, 1, 0, 0],
            "spend": [0.0, 40.0, 0.0, 0.0],
        }
    )


def test_row_count_is_unchanged():
    assert len(transform(make_raw())) == 4


def test_customer_id_is_unique_and_starts_at_one():
    ids = transform(make_raw())["customer_id"]
    assert ids.is_unique
    assert ids.tolist() == [1, 2, 3, 4]


def test_surburban_typo_is_fixed():
    zips = set(transform(make_raw())["zip_code"])
    assert "Surburban" not in zips
    assert "Suburban" in zips


def test_arm_codes_and_treatment_flag():
    df = transform(make_raw())
    assert df["arm"].tolist() == ["mens", "womens", "control", "mens"]
    assert df["is_treated"].tolist() == [1, 1, 0, 1]


def test_purchase_history_type():
    assert transform(make_raw())["purchase_history_type"].tolist() == [
        "mens_only", "womens_only", "both", "mens_only",
    ]


def test_recency_band():
    assert transform(make_raw())["recency_band"].tolist() == [
        "01-03 months", "04-06 months", "07-09 months", "10-12 months",
    ]


def test_history_segment_order():
    assert transform(make_raw())["history_segment_order"].tolist() == [1, 2, 7, 3]


def test_raw_input_is_not_modified():
    raw = make_raw()
    transform(raw)
    assert "customer_id" not in raw.columns
    assert "Surburban" in set(raw["zip_code"])
