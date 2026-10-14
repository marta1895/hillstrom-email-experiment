"""
Phase 1 - Extract.

Downloads the Hillstrom e-mail experiment CSV into data/raw/,
verifies it with a SHA-256 checksum, and logs basic facts about the file.

Run from the project root:
    python -m pipeline.extract
"""

import hashlib
import logging
import sys
import time
from pathlib import Path

import requests

# --- Configuration -----------------------------------------------------------

SOURCE_URL = (
    "http://www.minethatdata.com/"
    "Kevin_Hillstrom_MineThatData_E-MailAnalytics_DataMiningChallenge_2008.03.20.csv"
)

RAW_DIR = Path("data/raw")
RAW_FILE = RAW_DIR / "hillstrom.csv"

# Fill this in after the first successful run (the script prints the value).
# From then on, any change to the source file makes the pipeline fail.
EXPECTED_SHA256 = "0e5893329d8b93cefecc571777672028290ab69865718020c78c7284f291aece"

EXPECTED_ROWS = 64_000  # data rows, excluding the header
MAX_ATTEMPTS = 3
TIMEOUT_SECONDS = 30

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
)
log = logging.getLogger("extract")


# --- Steps -------------------------------------------------------------------

def download(url: str, target: Path) -> None:
    """Download url to target, retrying on network errors."""
    target.parent.mkdir(parents=True, exist_ok=True)

    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            log.info("Downloading (attempt %d/%d): %s", attempt, MAX_ATTEMPTS, url)
            response = requests.get(url, timeout=TIMEOUT_SECONDS)
            response.raise_for_status()
            target.write_bytes(response.content)
            return
        except requests.RequestException as error:
            log.warning("Attempt %d failed: %s", attempt, error)
            if attempt < MAX_ATTEMPTS:
                time.sleep(2 * attempt)

    log.error(
        "Download failed after %d attempts. If the source link is dead, "
        "download the CSV manually and save it as %s, then run this script again.",
        MAX_ATTEMPTS,
        target,
    )
    sys.exit(1)


def sha256_of(path: Path) -> str:
    """Return the SHA-256 checksum of a file."""
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(8192), b""):
            digest.update(chunk)
    return digest.hexdigest()


def verify_checksum(path: Path) -> None:
    """Fail if the file differs from the one the analysis was built on."""
    actual = sha256_of(path)

    if EXPECTED_SHA256 is None:
        log.warning("No expected checksum set yet. Actual SHA-256: %s", actual)
        log.warning("Copy that value into EXPECTED_SHA256 in pipeline/extract.py.")
        return

    if actual != EXPECTED_SHA256:
        log.error("Checksum mismatch! Expected %s, got %s", EXPECTED_SHA256, actual)
        sys.exit(1)

    log.info("Checksum OK.")


def log_file_facts(path: Path) -> None:
    """Log file size and row count, and warn if the row count is unexpected."""
    size_kb = path.stat().st_size / 1024
    with path.open("r", encoding="utf-8") as file:
        data_rows = sum(1 for _ in file) - 1  # minus header

    log.info("File: %s | size: %.1f KB | data rows: %d", path, size_kb, data_rows)

    if data_rows != EXPECTED_ROWS:
        log.error("Expected %d rows, found %d.", EXPECTED_ROWS, data_rows)
        sys.exit(1)


def main() -> None:
    if RAW_FILE.exists():
        log.info("Raw file already exists, skipping download: %s", RAW_FILE)
    else:
        download(SOURCE_URL, RAW_FILE)

    verify_checksum(RAW_FILE)
    log_file_facts(RAW_FILE)
    log.info("Extract finished.")


if __name__ == "__main__":
    main()
