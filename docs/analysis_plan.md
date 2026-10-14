# Analysis Plan (Pre-registration)
 
**Project:** Hillstrom Email Experiment
**Author:** Marta Narozhnyak
**Date committed:** 2026-10-14
**Status:** Written before any outcome was analysed by experiment arm.
 
---
 
## 1. Business question
 
Should the retailer send the Men's email, the Women's email, or no email, and to which customers?
 
The analysis ends with a targeting recommendation and its expected incremental profit.
 
## 2. Data
 
- Source: MineThatData E-Mail Analytics Challenge (Kevin Hillstrom, 2008).
- 64,000 customers who purchased in the last 12 months.
- Randomly assigned to three arms of roughly 1/3 each: Mens E-Mail, Womens E-Mail, No E-Mail (control).
- Outcomes tracked for two weeks after the send: `visit`, `conversion`, `spend`.
What was inspected before this plan was committed: column names, data types, row count. No outcome was examined by arm.
 
## 3. Metrics
 
| Metric | Definition | Role | Method |
| --- | --- | --- | --- |
| Conversion rate | conversions / customers in arm | **Primary** | Two-proportion z-test, 95% CI |
| Spend per customer | total spend / customers in arm (zeros included) | Secondary | Bootstrap CI of the difference (10,000 resamples); Welch t-test for comparison |
| Visit rate | visits / customers in arm | Secondary | Two-proportion z-test, 95% CI |
| Average order value | spend / converters in arm | Guardrail | Bootstrap CI; must not drop meaningfully |
| Sample ratio | customers per arm vs expected 1/3 | Validity check | Chi-square goodness of fit; flag if p < 0.001 |
| Covariate balance | standardised mean difference per pre-period feature | Validity check | Flag any feature with SMD > 0.1 |
 
## 4. Hypotheses (primary metric)
 
For each email (Mens, Womens) compared with control:
 
- H0: conversion(email) = conversion(control)
- H1: conversion(email) ≠ conversion(control), two-sided
## 5. Decision rules fixed in advance
 
- Overall α = 0.05.
- Two primary comparisons (Mens vs control, Womens vs control), corrected with the **Holm** method.
- Mens vs Womens head to head is secondary and reported with its own CI.
- Every effect is reported as absolute (percentage points) and relative lift, with a 95% CI. No result is reported as a p-value alone.
- If the sample ratio or balance check fails, results are reported with that warning and no recommendation is made until it is explained.
## 6. Segment analysis (exploratory)
 
Segments: purchase history (men's only, women's only, both), newbie, zip code type, channel, history segment, recency band.
 
- All segment results are **exploratory** and labelled that way.
- A segment cell is reported only if it has at least 1,000 customers per arm.
- No segment result is called "significant" without correction for the number of comparisons.
## 7. Minimum business effect and power
 
**Minimum effect of business interest:** +0.3 percentage points of conversion versus control.
 
Power calculation: ~21,300 customers per arm, α = 0.025 per test (Holm worst case), power = 0.80. The control conversion rate is unknown before analysis, so the minimum detectable effect (MDE) is computed for assumed baselines:
 
| Assumed control conversion | MDE (absolute) | MDE (relative) |
| --- | --- | --- |
| 0.5% | 0.21 pp | 42% |
| 1.0% | 0.30 pp | 30% |
| 2.0% | 0.42 pp | 21% |
 
Interpretation: if the true baseline is around 1% or lower, the test can detect the +0.3 pp effect of interest. If it is near 2%, effects of +0.3 pp may go undetected; a non-significant result then means "not enough power", not "no effect".
 
## 8. Cost assumptions (for the profit model)
 
These are **assumptions**, not data. The dataset contains no costs.
 
- Cost per email sent: **$0.01**
- Gross margin on incremental spend: **40%**
Incremental profit per policy = incremental spend × margin − emails sent × cost per email.
 
Sensitivity: the recommendation is recalculated with each assumption halved and doubled. If the recommended policy changes, that is reported.
 
## 9. Known limitations
 
- Data is from 2008; email behaviour has changed since.
- Only a two-week outcome window; no data on unsubscribes or long-term effects.
- No customer IDs, timestamps or costs in the source data.
- Segment findings are exploratory and need a follow-up test to confirm.
 