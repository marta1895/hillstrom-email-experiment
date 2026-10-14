"""
Phase 2, step B - Validate the raw data.

Runs three kinds of checks on data/raw/hillstrom.csv:

1. Schema rules (pandera): columns, types, allowed values, ranges.
2. Business-logic rules: relationships between columns that must hold.
3. Soft rules: things worth reporting that do not block the pipeline.

Writes docs/data_quality_report.md and exits with an error if any
hard rule fails, so bad data never reaches the database.

Run from the project root:
    python -m pipeline.validate
"""

import logging
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

import pandas as pd
import pandera.pandas as pa

RAW_FILE = Path("data/raw/hillstrom.csv")
REPORT_FILE = Path("docs/data_quality_report.md")

EXPECTED_ROWS = 64_000

# Exact spellings found by pipeline/profile.py.
# "Surburban" is misspelled in the source; it is fixed in transform, not here.
HISTORY_SEGMENTS = {
    "1) $0 - $100": (0, 100),
    "2) $100 - $200": (100, 200),
    "3) $200 - $350": (200, 350),
    "4) $350 - $500": (350, 500),
    "5) $500 - $750": (500, 750),
    "6) $750 - $1,000": (750, 1000),
    "7) $1,000 +": (1000, float("inf")),
}
ZIP_CODES = ["Surburban", "Urban", "Rural"]
CHANNELS = ["Web", "Phone", "Multichannel"]
SEGMENTS = ["Womens E-Mail", "Mens E-Mail", "No E-Mail"]

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
)
log = logging.getLogger("validate")


@dataclass
class RuleResult:
    name: str
    severity: str  # "hard" blocks the pipeline, "soft" is reported only
    violations: int

    @property
    def passed(self) -> bool:
        return self.violations == 0


# --- 1. Schema rules ---------------------------------------------------------

binary = [pa.Check.isin([0, 1])]

SCHEMA = pa.DataFrameSchema(
    {
        "recency": pa.Column(int, pa.Check.in_range(1, 12)),
        "history_segment": pa.Column(str, pa.Check.isin(list(HISTORY_SEGMENTS))),
        "history": pa.Column(float, pa.Check.gt(0)),
        "mens": pa.Column(int, binary),
        "womens": pa.Column(int, binary),
        "zip_code": pa.Column(str, pa.Check.isin(ZIP_CODES)),
        "newbie": pa.Column(int, binary),
        "channel": pa.Column(str, pa.Check.isin(CHANNELS)),
        "segment": pa.Column(str, pa.Check.isin(SEGMENTS)),
        "visit": pa.Column(int, binary),
        "conversion": pa.Column(int, binary),
        "spend": pa.Column(float, pa.Check.ge(0)),
    },
    strict=True,  # no missing or extra columns
    coerce=False,
)


def check_schema(df: pd.DataFrame) -> list[RuleResult]:
    """Run the pandera schema and turn each failed check into a RuleResult."""
    try:
        SCHEMA.validate(df, lazy=True)  # lazy = collect all errors, not just the first
        return [RuleResult("Schema: columns, types, allowed values, ranges", "hard", 0)]
    except pa.errors.SchemaErrors as errors:
        cases = errors.failure_cases
        results = []
        for (column, check), group in cases.groupby(["column", "check"], dropna=False):
            label = f"Schema: {column} - {check}"
            results.append(RuleResult(label, "hard", len(group)))
        return results


# --- 2. Business-logic rules (hard) ------------------------------------------

def check_logic(df: pd.DataFrame) -> list[RuleResult]:
    results = []

    results.append(RuleResult(
        f"Row count equals {EXPECTED_ROWS:,}",
        "hard",
        abs(len(df) - EXPECTED_ROWS),
    ))

    # You cannot buy without visiting the site.
    bought_without_visit = (df["conversion"] == 1) & (df["visit"] == 0)
    results.append(RuleResult(
        "conversion = 1 requires visit = 1",
        "hard",
        int(bought_without_visit.sum()),
    ))

    # Spend and conversion must agree in both directions.
    spend_mismatch = (df["spend"] > 0) != (df["conversion"] == 1)
    results.append(RuleResult(
        "spend > 0 if and only if conversion = 1",
        "hard",
        int(spend_mismatch.sum()),
    ))

    # history must fall inside its own history_segment bucket (edges inclusive).
    lower = df["history_segment"].map({k: v[0] for k, v in HISTORY_SEGMENTS.items()})
    upper = df["history_segment"].map({k: v[1] for k, v in HISTORY_SEGMENTS.items()})
    known = lower.notna()  # unknown segments are already caught by the schema
    history = df.loc[known, "history"]
    outside_bucket = (history < lower[known]) | (history > upper[known])
    results.append(RuleResult(
        "history falls inside its history_segment bucket",
        "hard",
        int(outside_bucket.sum()),
    ))

    return results


# --- 3. Soft rules (reported, never block) -----------------------------------

def check_soft(df: pd.DataFrame) -> list[RuleResult]:
    results = []

    # No customer ID exists, so identical rows may be different customers
    # with the same attributes. Reported, never removed.
    results.append(RuleResult(
        "Fully identical rows (no customer ID to tell them apart)",
        "soft",
        int(df.duplicated().sum()),
    ))

    results.append(RuleResult(
        "Customers with mens = 0 and womens = 0",
        "soft",
        int(((df["mens"] == 0) & (df["womens"] == 0)).sum()),
    ))

    results.append(RuleResult(
        f"spend exactly at its maximum ({df['spend'].max():.2f}): possible cap",
        "soft",
        int((df["spend"] == df["spend"].max()).sum()),
    ))

    return results


# --- Report ------------------------------------------------------------------

def write_report(results: list[RuleResult], n_rows: int, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    hard_failed = [r for r in results if r.severity == "hard" and not r.passed]
    status = "FAILED" if hard_failed else "PASSED"

    lines = [
        "# Data Quality Report",
        "",
        f"- Generated: {datetime.now():%Y-%m-%d %H:%M}",
        f"- Source: `{RAW_FILE}`",
        f"- Rows checked: {n_rows:,}",
        f"- Overall status: **{status}**",
        "",
        "Hard rules block the pipeline. Soft rules are findings to explain, not errors.",
        "",
        "| Rule | Severity | Result | Rows affected |",
        "| --- | --- | --- | --- |",
    ]
    for r in results:
        if r.severity == "hard":
            result = "PASS" if r.passed else "FAIL"
        else:
            result = "OK" if r.passed else "FLAG"
        lines.append(f"| {r.name} | {r.severity} | {result} | {r.violations:,} |")

    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def run_checks(df: pd.DataFrame) -> list[RuleResult]:
    """All checks in order. Used by main() and by the tests."""
    return check_schema(df) + check_logic(df) + check_soft(df)


def main() -> None:
    df = pd.read_csv(RAW_FILE)
    results = run_checks(df)
    write_report(results, len(df), REPORT_FILE)

    for r in results:
        if r.passed:
            log.info("PASS  [%s] %s", r.severity, r.name)
        elif r.severity == "soft":
            log.warning("FLAG  [soft] %s: %d rows", r.name, r.violations)
        else:
            log.error("FAIL  [hard] %s: %d rows", r.name, r.violations)

    log.info("Report written to %s", REPORT_FILE)

    if any(r.severity == "hard" and not r.passed for r in results):
        log.error("Validation failed. Fix the data or the rule before continuing.")
        sys.exit(1)

    log.info("Validation passed.")


if __name__ == "__main__":
    main()
