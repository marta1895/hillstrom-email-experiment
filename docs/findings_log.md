# Findings Log
 
Data findings from profiling and validation (Phase 2).
Each entry: what I found, why it matters, and what I decided.

## Misspelled zip code value
- Found: zip_code contains "Surburban" (28,776 rows) instead of "Suburban".
- Why it matters: The wrong label would appear in SQL results and Tableau filters.
- Decision: Kept as it is in raw data and validation; corrected in transform.

## Dataset has 6,562 fully identical rows
- Found: 6,562 rows are exactly the same as another row. There is no customer ID, so two different customers with the same recency, segment, zip, channel and zero spend look identical. I can't tell if they are duplicates or different customers.
- Why it matters: If I delete them, I would remove people unevenly from the arms and break the experiment.
- Decision: Keep all 64,000 rows, never deduplicate, and report the count as a soft rule.

## No nulls, and all ranges are sane
- Found: No column has null values. Recency is 1–12, history is above 0, spend is 0–499.
- Why it matters: No need to fill in or drop rows, so arm sizes stay as randomised.
- Decision: No changes needed.

## Arm sizes are almost equal
- Found: Womens E-Mail: 21,387 / Mens E-Mail: 21,307 / No E-Mail: 21,306.
  The biggest and smallest arm differ by 81 customers.
- Why it matters: Almost equal arms are a sign that the random split worked. If they were very different, I could not trust the experiment.
- Decision: Check it with a sample ratio test (chi-square) in Phase 5.

## No customer has mens = 0 and womens = 0
- Found: Every customer bought from at least one category last year.
- Why it matters: purchase_history_type will only have three values: mens_only, womens_only, or both.
- Decision: Use these three groups in segment analysis.

## Spend values pile up at the minimum and the maximum
- Found: Almost every spend value is unique. Only two values repeat a lot: 29.99 (136 buyers) and 499.00 (12 buyers). No other value repeats more than 2 times.
- Checked: I looked at the 10 most common spend values and at the min and max.
  29.99 is the smallest spend and 499.00 is the biggest. Only 2 buyers spent between 450 and 498.99, but 12 spent exactly 499.00. Also, history has the same minimum, 29.99.
- Conclusion: Spend is a total for two weeks, not the price of one product.
  If 499 was a product price, some people would buy it plus something else and spend more than 499. Nobody did. So I think the data was cut at both ends: small values were raised to 29.99 and big values were lowered to 499.00. I can't be 100% sure without the data owner, but the numbers point to this.
- Why it matters: The real big and small purchases are lost, so average spend is not the real average. All arms are affected the same way, so the
  difference between arms is less affected. But if an email worked by making people buy a lot, part of that effect is hidden.
- Decision: I can't get the original values back, so I keep the data as it is and add this to the limitations in the README.