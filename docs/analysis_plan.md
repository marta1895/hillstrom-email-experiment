# Analysis Plan (Pre-registration)

**Project:** Hillstrom Email Experiment
**Author:** Marta Narozhnyak
**Date committed:** 2026-10-14

I wrote this plan before looking at any results by experiment arm.

---

## 1. Business question

Which email should the store send: the Men's email, the Women's email, or no email?
And which customers should get it?

The final answer will be a targeting recommendation with its expected extra profit.

## 2. Data

- Source: MineThatData E-Mail Analytics Challenge (Kevin Hillstrom, 2008).
- 64,000 customers who bought goods in the last 12 months.
- They were split at random into three groups of about 1/3 each:
  Mens E-Mail, Womens E-Mail, and No E-Mail (control).
- Results were tracked for two weeks after the email: `visit`, `conversion`, `spend`.

Before writing this plan, I only looked at column names, data types and row count.
I did not look at any results by group.

## 3. Metrics

| Metric | How it is calculated | Role | Test |
| --- | --- | --- | --- |
| Conversion rate | buyers / customers in the group | **Main metric** | Two-proportion z-test, 95% CI |
| Spend per customer | total spend / customers in the group (people who spent $0 included) | Second metric | Bootstrap CI (10,000 resamples); Welch t-test to compare |
| Visit rate | visitors / customers in the group | Second metric | Two-proportion z-test, 95% CI |
| Average order value | total spend / buyers in the group | Guardrail (must not get much worse) | Bootstrap CI |
| Group sizes | customers per group vs the expected 1/3 | Check the split | Chi-square test; flag if p < 0.001 |
| Customer balance | difference between groups for each customer feature (SMD) | Check the split | Flag any feature with SMD > 0.1 |

## 4. Hypotheses (main metric)

For each email (Mens and Womens) compared with no email:

- H0: the email does not change the conversion rate.
- H1: the email changes the conversion rate (up or down).

## 5. Rules I set before seeing results

- Significance level: α = 0.05.
- I run two main tests (Mens vs control, Womens vs control),
  so I correct for that with the **Holm** method.
- Mens vs Womens directly is a second question, reported with its own CI (Confidence interval).
- Every result is shown as an absolute lift (percentage points) and a relative lift (%),
  both with a 95% CI. I never report a p-value alone.
- If the group-size check or the balance check fails, I report it as a warning
  and make no recommendation until I find the reason.

## 6. Segment analysis (exploratory)

Segments: purchase history (men's only, women's only, both), new vs returning customer,
zip code type, channel, history segment, recency band.

- All segment results are exploratory and labelled that way.
- I only report a segment if it has at least 1,000 customers in each group.
- I don't call a segment result "significant" without correcting for the number of segments tested.

## 7. Smallest useful effect and power

**Smallest effect worth acting on:** +0.3 percentage points of conversion compared with no email.

With about 21,300 customers per group, α = 0.025 per test (Holm, worst case) and power = 80%,
this is the smallest lift the experiment can reliably detect (MDE).
I don't know the control conversion rate before the analysis, so I calculate it for three guesses:

| If control conversion is | Smallest detectable lift | As a relative lift |
| --- | --- | --- |
| 0.5% | 0.21 pp | 42% |
| 1.0% | 0.30 pp | 30% |
| 2.0% | 0.42 pp | 21% |

What this means: if control conversion is about 1% or lower, the test can detect +0.3 pp.
If it is close to 2%, a +0.3 pp lift could be missed. Then "no significant result"
would mean "not enough data", not "the email does nothing".

## 8. Cost assumptions (for the profit calculation)

These are my **assumptions**, not data. The dataset has no costs.

- Cost of sending one email: **$0.01**
- Profit margin on extra spend: **40%**

Extra profit = extra spend × margin − number of emails × cost per email.

To test how much the answer depends on these guesses, I recalculate with each one
halved and doubled. If the best choice changes, I report that.

## 9. Known limitations

- The data is from 2008. Email marketing has changed since then.
- Results cover only two weeks. There is no data on unsubscribes or long-term effects.
- The data has no customer IDs, dates or costs.
- Segment findings are exploratory and would need a new test to confirm.