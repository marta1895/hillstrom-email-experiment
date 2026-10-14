# Data Quality Report

- Generated: 2026-10-14 13:58
- Source: `data/raw/hillstrom.csv`
- Rows checked: 64,000
- Overall status: **PASSED**

Hard rules block the pipeline. Soft rules are findings to explain, not errors.

| Rule | Severity | Result | Rows affected |
| --- | --- | --- | --- |
| Schema: columns, types, allowed values, ranges | hard | PASS | 0 |
| Row count equals 64,000 | hard | PASS | 0 |
| conversion = 1 requires visit = 1 | hard | PASS | 0 |
| spend > 0 if and only if conversion = 1 | hard | PASS | 0 |
| history falls inside its history_segment bucket | hard | PASS | 0 |
| Fully identical rows (no customer ID to tell them apart) | soft | FLAG | 6,562 |
| Customers with mens = 0 and womens = 0 | soft | OK | 0 |
| spend exactly at its maximum (499.00): possible cap | soft | FLAG | 12 |
