# Hillstrom Email Experiment: which email should we send?
 
**Answer: send the Mens email to everyone.** It doubles conversion compared with no email
and brings about **$19,000 extra profit** for 64,000 customers. Sending different emails
to different customer groups adds only $183 (1%), so it is not worth the extra work.
 
![Dashboard](tableau/screenshots/dashboard.png)
 
Interactive dashboard: [Tableau Public](https://public.tableau.com/app/profile/marta.narozhnyak/viz/HillstromEmailExperiment/HillstromEmailExperiment)
 
---
 
## The question
 
An online retailer ran an email test on 64,000 customers. Each customer was put at random
into one of three groups:
 
- **Mens email:** got an email with men's products
- **Womens email:** got an email with women's products
- **No email:** got nothing (the control group)

Two weeks later, we know who visited the site, who bought, and how much they spent.
 
So, the question is: **Which email should the retailer send, and to whom?**
 
## Key results
 
All results compare each email with the no-email group.
 
| | No email | Mens email | Womens email |
| --- | --- | --- | --- |
| Visit rate | 10.62% | 18.28% | 15.14% |
| Conversion rate | 0.57% | 1.25% | 0.88% |
| Spend per customer | $0.65 | $1.42 | $1.08 |
 
| Effect vs no email | Mens email | Womens email |
| --- | --- | --- |
| Conversion lift | **+0.68 pp** (95% range +0.50 to +0.86) | **+0.31 pp** (95% range +0.15 to +0.47) |
| Visit lift | +7.66 pp (+6.99 to +8.32) | +4.52 pp (+3.89 to +5.16) |
| Spend lift per customer | +$0.77 (+$0.49 to +$1.06) | +$0.42 (+$0.16 to +$0.68) |
| Is it luck? | No (p < 0.001) | No (p < 0.001) |
| Extra profit, email to all 64,000 customers | **$19,014** | $10,246 |
 
**What this means:**
 
- **Both emails really work.** The gaps are far too big to be luck.
- **The Mens email is clearly worth sending.** Before looking at the results, I decided that an
  email must add at least +0.3 pp conversion to be worth it. Even the lowest value of the Mens
  range (+0.50 pp) is above that line.
- **The Womens email is uncertain.** It works, but about half of its range is below +0.3 pp.
  It still pays for itself: it would lose money only if one email cost more than about $0.06.
- **The Mens email works for every customer group**, including people who bought only women's
  items last year (+0.57 pp). The Womens email does almost nothing for men's-only buyers (+0.06 pp).
- **Targeting is not worth it.** Choosing the best email for each customer group earns $19,197,
  only $183 more than sending the Mens email to everyone.
## How I did it
 
1. **Wrote the analysis plan first.** Main metric, tests and the "worth it" line were committed
   to git before I looked at any results ([analysis plan](docs/analysis_plan.md)).
2. **Built a data pipeline in Python:** download the data, check it, clean it, load it into PostgreSQL.
   The pipeline stops if the data breaks any rule ([data quality report](docs/data_quality_report.md)).
3. **Analysed the data in SQL:** group sizes, customer balance, funnel, lift, segments, spend
   shape, anomalies and profit ([SQL files](sql/analysis)).
4. **Tested the results in Python:** chi-square test for group sizes, z-tests with 95% ranges for
   visits and conversion, and a bootstrap (checked with a t-test) for spend
   ([notebook](analysis/01_experiment_readout.ipynb)).
5. **Built a Tableau dashboard** with the main results.
Every finding, with what I checked and what I decided, is in the [findings log](docs/findings_log.md).
 
## Data quality findings
 
- **6,562 rows are fully identical.** The data has no customer ID, so I can't tell if they are
  duplicates or different customers with the same values. I kept them all: deleting them would
  remove people unevenly from the groups.
- **"Surburban" is misspelled** in 28,776 rows. Kept as it is in the raw data, fixed in cleaning.
- **Spend looks cut at both ends.** 136 buyers spent exactly $29.99 and 12 spent exactly $499,
  and nobody spent more than $499. History has the same $29.99 minimum (7,947 customers).
  So the real smallest and biggest purchases are probably hidden.
- **The random split worked.** Group sizes are almost exactly 1/3 each (chi-square p = 0.90),
  and customers are similar in every group.
## Limitations
 
- The data is from 2008, and email marketing has changed since then.
- Results cover only two weeks after the email. There is no data on unsubscribes or long-term effects.
- Spend values seem to be cut at $29.99 and $499, so average spend is not fully accurate.
- The data has no costs. Profit uses my own assumptions: $0.01 per email and a 40% margin.
  The Womens email stays profitable unless one email costs more than about $0.06.
- Segment results are exploratory: about 20 segments were checked, so some differences can be luck.
 
## Project structure
 
```
hillstrom-email-experiment/
├── docs/
│   ├── analysis_plan.md          plan written before the analysis
│   ├── data_quality_report.md    created by the pipeline
│   └── findings_log.md           every finding and decision
├── pipeline/                     extract, profile, validate, transform, load (Python)
├── sql/
│   ├── raw/, staging/, marts/    database layers
│   ├── checks/                   reconciliation between layers
│   └── analysis/                 analysis queries 01-09
├── analysis/                     statistical tests (Jupyter notebook)
├── tests/                        tests for validation and cleaning
├── tableau/                      dashboard workbook, data and screenshot
├── Makefile
└── requirements.txt
```
 
## Data source
 
[MineThatData E-Mail Analytics and Data Mining Challenge](https://blog.minethatdata.com/2008/03/minethatdata-e-mail-analytics-and-data.html), Kevin Hillstrom, 2008.
 
## Tools
 
Python (pandas, pandera, scipy, statsmodels, pytest) · PostgreSQL · SQL · Tableau
 