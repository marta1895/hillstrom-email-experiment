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
- Decision: Check it with a sample ratio test (chi-square) later.

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
- Why it matters: The real big and small purchases are lost, so average spend is not the real average. All arms are affected the same way, so the difference between arms is less affected. But if an email worked by making people buy a lot, part of that effect is hidden.
- Decision: I can't get the original values back, so I keep the data as it is and add this to the limitations in the README file.

## Arms are balanced on pre-experiment features
- Found: The largest gap is phone channel: 44.20% in womens vs 43.37% in mens, a difference of 0.83 percentage points. Web channel is close (0.80 pp).
    All other percentage gaps are below 0.6 pp.
    Average history differs by less than $2 (240.88 vs 242.84), under 1%.
    Average recency is almost the same in all arms (5.75 vs 5.77 months).
- Why it matters: So the random split worked, and differences between arms in the results can be explained by the emails, not by different customers.
- Decision: continue the analysis, and confirm balance with a statistical measure later.

## Mens email works for all customer groups; Womens email does not
- Found: The Mens email lifts conversion in every segment, mostly +0.5 to +0.9 pp.
  Biggest lift: customers who bought both men's and women's items
  (0.93% -> 2.43%, +1.50 pp). It also works for women's only buyers
  (0.52% -> 1.09%, +0.57 pp). The Womens email does almost nothing for men's only buyers (0.55% -> 0.61%, +0.06 pp).
- Why it matters: This explains why Mens is stronger overall. It reaches all customers, while the Womens email mostly works only for people who already buy women's items. It also means sending the Womens email to men's only buyers is likely wasted.
- Decision: Use this in the targeting analysis. Results are exploratory (about 20 segments tested), so they need confidence intervals in the statistical analysis before any recommendation.

## Some segment results are not reliable
- Found: History segments $750-1,000 and $1,000+ have fewer than 1,000 customers per arm. Their lifts look very large (up to +2.00 pp, +415%), but are based on only about 5-15 buyers. The Womens email also shows small negative lifts in two history segments ($200-350: -0.07 pp, $350-500: -0.22 pp).
- Why it matters: With few buyers, a couple of purchases more or less changes the result completely. And when about 20 segments are tested, a few results go the "wrong" way just by luck.
- Decision: Ignore segments marked enough_customers = FALSE. Do not explain the negative lifts as a real effect of the email; note them as likely noise.