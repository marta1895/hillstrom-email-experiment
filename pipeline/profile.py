"""
Phase 2, step A - Profile the raw data.

Prints the facts needed to write validation rules: types, nulls,
duplicates, distinct values of every text column, and ranges of every
numeric column.

It deliberately does NOT break outcomes down by experiment arm:
that would break the pre-registration.

Run from the project root:
    python -m pipeline.profile
"""

from pathlib import Path

import pandas as pd

RAW_FILE = Path("data/raw/hillstrom.csv")


def main() -> None:
    df = pd.read_csv(RAW_FILE)

    print("=" * 60)
    print(f"SHAPE: {df.shape[0]:,} rows x {df.shape[1]} columns")

    print("\n" + "=" * 60)
    print("COLUMNS AND TYPES")
    print(df.dtypes.to_string())

    print("\n" + "=" * 60)
    print("NULLS PER COLUMN")
    print(df.isna().sum().to_string())

    print("\n" + "=" * 60)
    print(f"FULLY DUPLICATED ROWS: {df.duplicated().sum():,}")

    print("\n" + "=" * 60)
    print("DISTINCT VALUES OF TEXT COLUMNS")
    for column in df.select_dtypes(exclude="number").columns:
        print(f"\n--- {column} ---")
        print(df[column].value_counts(dropna=False).to_string())

    print("\n" + "=" * 60)
    print("NUMERIC COLUMNS: RANGE AND DISTINCT COUNT")
    numeric = df.select_dtypes(include="number")
    summary = pd.DataFrame(
        {
            "min": numeric.min(),
            "max": numeric.max(),
            "n_distinct": numeric.nunique(),
        }
    )
    print(summary.to_string())


if __name__ == "__main__":
    main()
