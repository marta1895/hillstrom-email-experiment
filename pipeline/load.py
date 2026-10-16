"""
Phase 3 - Load the data into PostgreSQL and build the SQL layers.

Steps, all inside ONE transaction (if any step fails, nothing changes):
1. create the raw, staging and marts schemas
2. load data/raw/hillstrom.csv into raw.hillstrom (as downloaded)
3. load data/processed/customers.csv into staging.customers
4. build the mart views
5. reconcile row counts and total spend across all layers

Connection settings come from the .env file (never committed to git).
See .env.example.

Run from the project root (after transform):
    python -m pipeline.load
"""

import csv
import logging
import sys
from pathlib import Path

import psycopg
from dotenv import load_dotenv
from psycopg import sql

RAW_FILE = Path("data/raw/hillstrom.csv")
PROCESSED_FILE = Path("data/processed/customers.csv")
SQL_DIR = Path("sql")

EXPECTED_ROWS = 64_000

# SQL files run in this order. Tables first, then the views built on them.
SCHEMA_FILES = ["00_schemas.sql", "raw/hillstrom.sql", "staging/customers.sql"]
MART_FILES = [
    "marts/customer_outcomes.sql",
    "marts/arm_summary.sql",
    "marts/segment_arm_summary.sql",
]
RECONCILIATION_FILE = "checks/reconciliation.sql"

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
)
log = logging.getLogger("load")


def run_sql_file(conn: psycopg.Connection, relative_path: str) -> None:
    log.info("Running %s", relative_path)
    conn.execute((SQL_DIR / relative_path).read_text(encoding="utf-8"))


def copy_csv(conn: psycopg.Connection, csv_path: Path, schema: str, table: str) -> None:
    """Load a CSV into a table with COPY, the fastest way to bulk-load Postgres.
    Column names are taken from the CSV header, so column order never matters."""
    with csv_path.open(encoding="utf-8", newline="") as file:
        columns = next(csv.reader(file))
        statement = sql.SQL("COPY {} ({}) FROM STDIN WITH (FORMAT csv)").format(
            sql.Identifier(schema, table),
            sql.SQL(", ").join(sql.Identifier(c) for c in columns),
        )
        with conn.cursor() as cursor, cursor.copy(statement) as copy:
            while chunk := file.read(65_536):
                copy.write(chunk)
    log.info("Loaded %s into %s.%s", csv_path, schema, table)


def reconcile(conn: psycopg.Connection) -> None:
    """Every layer must hold the same number of customers and the same spend."""
    query = (SQL_DIR / RECONCILIATION_FILE).read_text(encoding="utf-8")
    rows = conn.execute(query).fetchall()

    raw_spend = rows[0][2]
    problems = 0
    for check_name, row_count, total_spend in rows:
        ok = row_count == EXPECTED_ROWS and total_spend == raw_spend
        log.info(
            "%s  %-45s rows=%s  spend=%s",
            "OK  " if ok else "FAIL", check_name, f"{row_count:,}", total_spend,
        )
        problems += not ok

    if problems:
        raise RuntimeError(f"Reconciliation failed for {problems} check(s).")


def main() -> None:
    load_dotenv()  # reads PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD from .env

    for path in (RAW_FILE, PROCESSED_FILE):
        if not path.exists():
            log.error("Missing %s. Run extract, validate and transform first.", path)
            sys.exit(1)

    try:
        # The "with" block is one transaction: commit at the end, rollback on error.
        with psycopg.connect() as conn:
            for file in SCHEMA_FILES:
                run_sql_file(conn, file)

            copy_csv(conn, RAW_FILE, "raw", "hillstrom")
            copy_csv(conn, PROCESSED_FILE, "staging", "customers")

            for file in MART_FILES:
                run_sql_file(conn, file)

            reconcile(conn)
    except (psycopg.Error, RuntimeError) as error:
        log.error("Load failed, nothing was changed in the database: %s", error)
        sys.exit(1)

    log.info("Load finished.")


if __name__ == "__main__":
    main()
