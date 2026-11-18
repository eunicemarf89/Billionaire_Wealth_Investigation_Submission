# The Billionaire Wealth Investigation: SQL & Data Analytics Project

![SQL](https://img.shields.io/badge/SQL-PostgreSQL-0B2545?style=flat-square)
![Excel](https://img.shields.io/badge/Excel-Live%20formulas%20%2B%20charts-14808A?style=flat-square)
![Questions](https://img.shields.io/badge/Questions-10%20core%20%2B%209%20extra-C9A227?style=flat-square)
![Status](https://img.shields.io/badge/Status-Complete-16A34A?style=flat-square)

**Business scenario.** As a Junior Data Analyst at a global financial research organisation, I analysed the Forbes Top 200 richest people (N = 200) with SQL to understand how wealth is distributed by country, industry and age.

## Headline findings

| Metric | Result |
| :-- | :-- |
| Combined net worth | **$6,368.5B** ($6.37 trillion) |
| Average vs median fortune | **$31.84B** vs **$19.25B**. 147 of 200 people (73.5%) are below the average |
| Average age | **69.4 years**. Only 16 people are under 50, holding 7.98% of wealth |
| United States | **79 billionaires (39.5%)** holding **$3,130.9B (49.16%)** |
| Top 20 people | **38.95%** of all wealth ($2,480.3B) |
| Industry leader | **Technology**: 40 people, $1,738.8B, and the highest average ($43.47B) among industries with 3+ billionaires |
| Q10 caveat | Telecom ranks first on average ($102B) but contains **one person**, so a minimum-sample version (Q10b) is provided |

## Repository structure

```text
├── README.md
├── 01_setup_schema_and_data.sql              # Table, constraints and all 200 rows (no CSV import needed)
├── 02_analysis_queries.sql                   # Validation + 10 core questions + 9 extra questions
├── Billionaire_Wealth_Executive_Report.pdf   # 7-page report with 6 charts
├── Billionaire_Wealth_Analysis_Workbook.xlsx # Live-formula dashboard, 3 charts, a tab per question
├── Top_200_Richest_Person_in_the_World.csv   # Source data
├── charts/                                   # Report charts as PNG
└── query_results_csv/                        # 22 exported result sets
```

## How to reproduce

1. Run `01_setup_schema_and_data.sql` in PostgreSQL (pgAdmin or psql). It creates the table and inserts all 200 rows. The final line should return `200 | 6368.50`.
2. Run `02_analysis_queries.sql` query by query. Compare with `query_results_csv/`.

Schema note: column names follow the CSV (including `rank`). Only `networth_billion_US_dollars` is shortened to `net_worth_bn`.

## Questions answered

| # | Question | SQL techniques |
| :-- | :-- | :-- |
| A1-A2 | Data validation (nulls, duplicates, ranges, rank consistency) | `COUNT DISTINCT`, conditional `SUM`, self-join |
| Q1 | 20 richest | `ORDER BY` with tie-breaker, `LIMIT` |
| Q2 | 5 youngest | Multi-column sort, tie check at the cut-off |
| Q3 | Average age and net worth (+ median) | `AVG`, `ROW_NUMBER()` median, CTE |
| Q4 | 5 most represented countries | `GROUP BY`, scalar subquery for % |
| Q5 | Combined net worth per country | `SUM`, `AVG`, share of total |
| Q6 | 5 industries by headcount | `GROUP BY`, `COUNT` |
| Q7 | Countries with 5+ billionaires | `HAVING` |
| Q8 | Wealth of those under 50 | `WHERE`, aggregates, share |
| Q9 | Above-average net worth | Scalar subquery in `WHERE` and `SELECT` |
| Q10 / Q10b | Highest average industry, and robust version with 3+ people | `GROUP BY`, `HAVING` |
| Q11 | Richest person per industry | CTE, `ROW_NUMBER() OVER (PARTITION BY ...)` |
| Q12 | Wealth by age cohort | CTE + `CASE` |
| Q13 | Top 10% vs bottom 90% | Window function, `CASE` |
| Q14 | Cumulative wealth at Top 1/5/10/20/50/100 | Running `SUM() OVER` |
| Q15 | Wealth share vs headcount share per industry | Ratio index |
| Q16 | Richest person in each large country | CTE, join, window |
| Q17 | Net worth bands | `CASE` banding |
| Q18 | Five oldest billionaires | Sorting |
| Q19 | United States vs rest of world | `CASE` grouping |

## Data notes and limitations

- Single snapshot of the Forbes list. No trend over time.
- One country and one primary industry per person. "& family" entries count as one billionaire.
- Ranks in the source contain ties (137 distinct ranks), so queries order by net worth first.
- Averages for industries with 1 to 3 people are not reliable, which is why Q10b exists.
