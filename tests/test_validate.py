"""
Tests for pipeline/validate.py.

Each test breaks the data in one specific way and asserts that the
matching rule catches it. A validation step that has never been seen
to fail cannot be trusted to work.

Run from the project root:
    pytest
"""

import pandas as pd
import pytest

from pipeline.validate import run_checks


def make_valid_rows(n: int = 6) -> pd.DataFrame:
    """A small dataset that passes every hard rule."""
    rows = [
        # recency, history_segment, history, mens, womens, zip_code, newbie,
        # channel, segment, visit, conversion, spend
        (10, "2) $100 - $200", 142.44, 1, 0, "Surburban", 0, "Phone", "Womens E-Mail", 0, 0, 0.0),
        (6, "3) $200 - $350", 329.08, 1, 1, "Rural", 1, "Web", "No E-Mail", 1, 0, 0.0),
        (7, "2) $100 - $200", 180.65, 0, 1, "Surburban", 1, "Web", "Womens E-Mail", 1, 1, 55.0),
        (9, "5) $500 - $750", 675.83, 1, 0, "Rural", 1, "Web", "Mens E-Mail", 0, 0, 0.0),
        (2, "1) $0 - $100", 45.34, 1, 0, "Urban", 0, "Web", "Womens E-Mail", 0, 0, 0.0),
        (1, "7) $1,000 +", 1250.0, 1, 1, "Urban", 0, "Multichannel", "Mens E-Mail", 1, 1, 120.5),
    ]
    columns = [
        "recency", "history_segment", "history", "mens", "womens", "zip_code",
        "newbie", "channel", "segment", "visit", "conversion", "spend",
    ]
    return pd.DataFrame(rows[:n], columns=columns)


def failed_hard_rules(df: pd.DataFrame) -> list[str]:
    """Names of hard rules that failed, ignoring the row-count rule
    (test data is deliberately small)."""
    return [
        r.name
        for r in run_checks(df)
        if r.severity == "hard" and not r.passed and not r.name.startswith("Row count")
    ]


def test_valid_data_passes_all_hard_rules():
    assert failed_hard_rules(make_valid_rows()) == []


def test_unknown_segment_is_caught():
    df = make_valid_rows()
    df.loc[0, "segment"] = "Kids E-Mail"
    assert any("segment" in name for name in failed_hard_rules(df))


def test_recency_out_of_range_is_caught():
    df = make_valid_rows()
    df.loc[0, "recency"] = 13
    assert any("recency" in name for name in failed_hard_rules(df))


def test_non_binary_flag_is_caught():
    df = make_valid_rows()
    df.loc[0, "visit"] = 2
    assert any("visit" in name for name in failed_hard_rules(df))


def test_negative_spend_is_caught():
    df = make_valid_rows()
    df.loc[0, "spend"] = -5.0
    assert any("spend" in name for name in failed_hard_rules(df))


def test_missing_column_is_caught():
    df = make_valid_rows().drop(columns=["channel"])
    assert failed_hard_rules(df) != []


def test_conversion_without_visit_is_caught():
    df = make_valid_rows()
    df.loc[0, ["visit", "conversion", "spend"]] = [0, 1, 30.0]
    assert "conversion = 1 requires visit = 1" in failed_hard_rules(df)


def test_spend_without_conversion_is_caught():
    df = make_valid_rows()
    df.loc[1, "spend"] = 40.0  # visit = 1, conversion = 0
    assert "spend > 0 if and only if conversion = 1" in failed_hard_rules(df)


def test_conversion_without_spend_is_caught():
    df = make_valid_rows()
    df.loc[1, "conversion"] = 1  # spend stays 0
    assert "spend > 0 if and only if conversion = 1" in failed_hard_rules(df)


@pytest.mark.parametrize("history", [250.0, 20.0])
def test_history_outside_its_bucket_is_caught(history):
    df = make_valid_rows()
    df.loc[0, "history"] = history  # row 0 is in "2) $100 - $200"
    assert "history falls inside its history_segment bucket" in failed_hard_rules(df)


def test_duplicates_are_flagged_but_do_not_fail():
    df = pd.concat([make_valid_rows(), make_valid_rows(1)], ignore_index=True)
    results = {r.name: r for r in run_checks(df)}
    duplicates = results["Fully identical rows (no customer ID to tell them apart)"]
    assert duplicates.severity == "soft"
    assert duplicates.violations == 1
    assert failed_hard_rules(df) == []
