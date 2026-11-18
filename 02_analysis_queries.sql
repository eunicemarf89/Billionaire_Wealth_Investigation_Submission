-- ============================================================================
-- THE BILLIONAIRE WEALTH INVESTIGATION  |  FILE 2 OF 2: ANALYSIS QUERIES
-- Role    : Junior Data Analyst, Global Financial Research Organisation
-- Table   : billionaires (created and loaded by 01_setup_schema_and_data.sql)
-- Units   : net_worth_bn is in billions of US dollars
-- Database: PostgreSQL (also runs unchanged in SQLite 3.25+)
-- Layout  : Section A = data validation | B = the 10 required questions
--           C = advanced analysis (CTEs, window functions) | D = extra questions
-- ============================================================================


-- ############################################################################
-- SECTION A. DATA VALIDATION (run before trusting any result)
-- ############################################################################

-- A1. Completeness and range checks. Expected: 200 rows, 0 NULLs, 0 duplicates.
SELECT
    COUNT(*)                                             AS total_rows,
    COUNT(DISTINCT name)                                 AS distinct_names,
    SUM(CASE WHEN age IS NULL OR net_worth_bn IS NULL
              OR country IS NULL OR industry IS NULL THEN 1 ELSE 0 END) AS rows_with_nulls,
    MIN(age)          AS min_age,          MAX(age)          AS max_age,
    MIN(net_worth_bn) AS min_net_worth_bn, MAX(net_worth_bn) AS max_net_worth_bn,
    COUNT(DISTINCT country)  AS distinct_countries,
    COUNT(DISTINCT industry) AS distinct_industries
FROM billionaires;

-- A2. Is rank consistent with net worth? (0 means yes: no one ranked
--     higher has a smaller fortune.) Rank ties in the source are Forbes ties.
SELECT COUNT(*) AS rank_order_violations
FROM billionaires a
JOIN billionaires b ON a.rank < b.rank
WHERE a.net_worth_bn < b.net_worth_bn;


-- ############################################################################
-- SECTION B. THE 10 REQUIRED BUSINESS QUESTIONS
-- ############################################################################

-- Q1. Retrieve the 20 richest billionaires.
-- Tie-safe: net worth DESC, then rank. The 20th ($77.0B) and 21st differ, so the cut is clean.
SELECT rank, name, age, country, industry, net_worth_bn
FROM billionaires
ORDER BY net_worth_bn DESC, rank ASC
LIMIT 20;

-- Q2. Identify the five youngest billionaires.
-- Ages 31, 37, 39, 39, 39. The next person is 40, so the five-row cut has no tie problem.
SELECT rank, name, age, country, industry, net_worth_bn
FROM billionaires
ORDER BY age ASC, net_worth_bn DESC
LIMIT 5;

-- Q3. Calculate the average age and average net worth.
-- Median is added because the mean alone is misleading for skewed wealth data.
WITH ordered AS (
    SELECT net_worth_bn,
           ROW_NUMBER() OVER (ORDER BY net_worth_bn) AS rn,
           COUNT(*)     OVER ()                      AS cnt
    FROM billionaires
), med AS (
    SELECT AVG(net_worth_bn) AS median_net_worth_bn
    FROM ordered
    WHERE rn IN (FLOOR((cnt + 1) / 2.0), FLOOR((cnt + 2) / 2.0))
)
SELECT
    ROUND(AVG(b.age), 2)           AS average_age,
    ROUND(AVG(b.net_worth_bn), 2)  AS average_net_worth_bn,
    ROUND(MAX(m.median_net_worth_bn), 2) AS median_net_worth_bn,
    ROUND(SUM(b.net_worth_bn), 2)  AS total_net_worth_bn,
    COUNT(*)                       AS total_billionaires
FROM billionaires b
CROSS JOIN med m;

-- Q4. Identify the five most represented countries.
-- Germany and Russia tie on 11, both fall inside the top 5, so no one is cut arbitrarily.
SELECT country,
       COUNT(*) AS billionaire_count,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM billionaires), 2) AS pct_of_top_200
FROM billionaires
GROUP BY country
ORDER BY billionaire_count DESC, country ASC
LIMIT 5;

-- Q5. Calculate the combined net worth of billionaires from each country.
SELECT country,
       COUNT(*)                          AS billionaire_count,
       ROUND(SUM(net_worth_bn), 2)       AS combined_net_worth_bn,
       ROUND(AVG(net_worth_bn), 2)       AS avg_net_worth_bn,
       ROUND(SUM(net_worth_bn) * 100.0 / (SELECT SUM(net_worth_bn) FROM billionaires), 2) AS share_of_total_wealth_pct
FROM billionaires
GROUP BY country
ORDER BY combined_net_worth_bn DESC;

-- Q6. Identify the five industries with the highest number of billionaires.
-- Diversified and Food & Beverage tie on 15 for 4th/5th, both are included.
SELECT industry,
       COUNT(*)                    AS billionaire_count,
       ROUND(SUM(net_worth_bn), 2) AS total_net_worth_bn,
       ROUND(AVG(net_worth_bn), 2) AS avg_net_worth_bn
FROM billionaires
GROUP BY industry
ORDER BY billionaire_count DESC, total_net_worth_bn DESC
LIMIT 5;

-- Q7. Find countries with at least five billionaires.
SELECT country,
       COUNT(*)                    AS billionaire_count,
       ROUND(SUM(net_worth_bn), 2) AS combined_net_worth_bn,
       ROUND(AVG(net_worth_bn), 2) AS avg_net_worth_bn
FROM billionaires
GROUP BY country
HAVING COUNT(*) >= 5
ORDER BY billionaire_count DESC, combined_net_worth_bn DESC;

-- Q8. Calculate the total wealth of billionaires younger than 50.
SELECT COUNT(*)                    AS billionaires_under_50,
       ROUND(SUM(net_worth_bn), 2) AS total_wealth_under_50_bn,
       ROUND(AVG(net_worth_bn), 2) AS avg_wealth_under_50_bn,
       ROUND(SUM(net_worth_bn) * 100.0 / (SELECT SUM(net_worth_bn) FROM billionaires), 2) AS share_of_total_wealth_pct,
       MIN(age) AS youngest_age,
       MAX(age) AS oldest_age_in_group
FROM billionaires
WHERE age < 50;

-- Q9. Identify billionaires whose net worth exceeds the overall average.
SELECT rank, name, age, country, industry, net_worth_bn,
       ROUND(net_worth_bn - (SELECT AVG(net_worth_bn) FROM billionaires), 2) AS excess_over_avg_bn
FROM billionaires
WHERE net_worth_bn > (SELECT AVG(net_worth_bn) FROM billionaires)
ORDER BY net_worth_bn DESC, rank ASC;

-- Q10. Identify the industry with the highest average net worth.
-- Telecom wins the raw ranking but contains ONE person (Carlos Slim). Q10b is the
-- robust version: only industries with at least 3 billionaires.
-- Q10a (as asked)
SELECT industry,
       COUNT(*)                    AS billionaire_count,
       ROUND(AVG(net_worth_bn), 2) AS avg_net_worth_bn,
       ROUND(SUM(net_worth_bn), 2) AS total_net_worth_bn
FROM billionaires
GROUP BY industry
ORDER BY avg_net_worth_bn DESC;

-- Q10b (robust: minimum sample size of 3)
SELECT industry,
       COUNT(*)                    AS billionaire_count,
       ROUND(AVG(net_worth_bn), 2) AS avg_net_worth_bn,
       ROUND(SUM(net_worth_bn), 2) AS total_net_worth_bn
FROM billionaires
GROUP BY industry
HAVING COUNT(*) >= 3
ORDER BY avg_net_worth_bn DESC
LIMIT 5;


-- ############################################################################
-- SECTION C. ADVANCED ANALYSIS (CTEs, window functions, CASE)
-- ############################################################################

-- Q11. Richest billionaire inside every industry (window function).
-- ROW_NUMBER guarantees exactly one leader per industry even if two people tie.
WITH ranked AS (
    SELECT industry, name, country, age, net_worth_bn,
           ROW_NUMBER() OVER (PARTITION BY industry ORDER BY net_worth_bn DESC, rank) AS rn
    FROM billionaires
)
SELECT industry, name AS industry_leader, country, age, net_worth_bn
FROM ranked
WHERE rn = 1
ORDER BY net_worth_bn DESC;

-- Q12. Wealth distribution across age cohorts.
WITH cohorts AS (
    SELECT net_worth_bn,
           CASE WHEN age < 40  THEN '1. Under 40'
                WHEN age < 60  THEN '2. 40-59'
                WHEN age < 80  THEN '3. 60-79'
                ELSE                '4. 80 and over' END AS age_cohort
    FROM billionaires
)
SELECT age_cohort,
       COUNT(*)                    AS billionaire_count,
       ROUND(SUM(net_worth_bn), 2) AS total_wealth_bn,
       ROUND(AVG(net_worth_bn), 2) AS avg_wealth_bn,
       ROUND(SUM(net_worth_bn) * 100.0 / (SELECT SUM(net_worth_bn) FROM billionaires), 2) AS wealth_share_pct
FROM cohorts
GROUP BY age_cohort
ORDER BY age_cohort;

-- Q13. Concentration: top 10% (ranks by net worth 1-20) vs the other 90%.
WITH ordered AS (
    SELECT net_worth_bn,
           ROW_NUMBER() OVER (ORDER BY net_worth_bn DESC, rank) AS pos
    FROM billionaires
)
SELECT CASE WHEN pos <= 20 THEN 'Top 10% (positions 1-20)' ELSE 'Bottom 90% (positions 21-200)' END AS wealth_tier,
       COUNT(*)                    AS billionaire_count,
       ROUND(SUM(net_worth_bn), 2) AS total_wealth_bn,
       ROUND(SUM(net_worth_bn) * 100.0 / (SELECT SUM(net_worth_bn) FROM billionaires), 2) AS share_of_wealth_pct,
       ROUND(AVG(net_worth_bn), 2) AS avg_wealth_bn
FROM ordered
GROUP BY CASE WHEN pos <= 20 THEN 'Top 10% (positions 1-20)' ELSE 'Bottom 90% (positions 21-200)' END
ORDER BY total_wealth_bn DESC;


-- ############################################################################
-- SECTION D. EXTRA QUESTIONS (own curiosity, per the project brief)
-- ############################################################################

-- Q14. How fast does wealth accumulate at the top? Cumulative share at Top 1, 5, 10, 20, 50, 100.
WITH ordered AS (
    SELECT net_worth_bn,
           ROW_NUMBER() OVER (ORDER BY net_worth_bn DESC, rank) AS pos,
           SUM(net_worth_bn) OVER (ORDER BY net_worth_bn DESC, rank
                                   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
    FROM billionaires
)
SELECT pos AS top_n_people,
       ROUND(running_total, 2) AS cumulative_wealth_bn,
       ROUND(running_total * 100.0 / (SELECT SUM(net_worth_bn) FROM billionaires), 2) AS cumulative_share_pct
FROM ordered
WHERE pos IN (1, 5, 10, 20, 50, 100, 200)
ORDER BY pos;

-- Q15. Which industries punch above their weight? Wealth share vs headcount share.
-- An index above 1.00 means the industry holds more wealth than its headcount suggests.
SELECT industry,
       COUNT(*) AS billionaire_count,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM billionaires), 2)              AS headcount_share_pct,
       ROUND(SUM(net_worth_bn) * 100.0 / (SELECT SUM(net_worth_bn) FROM billionaires), 2) AS wealth_share_pct,
       ROUND((SUM(net_worth_bn) / (SELECT SUM(net_worth_bn) FROM billionaires))
           / (COUNT(*) * 1.0 / (SELECT COUNT(*) FROM billionaires)), 2)              AS wealth_to_headcount_index
FROM billionaires
GROUP BY industry
ORDER BY wealth_share_pct DESC;

-- Q16. Richest billionaire in every country with at least 5 billionaires (CTE + window).
WITH big_countries AS (
    SELECT country FROM billionaires GROUP BY country HAVING COUNT(*) >= 5
), ranked AS (
    SELECT b.country, b.name, b.industry, b.net_worth_bn,
           ROW_NUMBER() OVER (PARTITION BY b.country ORDER BY b.net_worth_bn DESC, b.rank) AS rn
    FROM billionaires b
    JOIN big_countries c ON c.country = b.country
)
SELECT country, name AS richest_person, industry, net_worth_bn
FROM ranked
WHERE rn = 1
ORDER BY net_worth_bn DESC;

-- Q17. Net worth bands: how many billionaires sit at each fortune size?
WITH banded AS (
    SELECT net_worth_bn,
           CASE WHEN net_worth_bn >= 100 THEN '1. $100B and above'
                WHEN net_worth_bn >= 50  THEN '2. $50B - $99.9B'
                WHEN net_worth_bn >= 25  THEN '3. $25B - $49.9B'
                ELSE                          '4. Below $25B' END AS wealth_band
    FROM billionaires
)
SELECT wealth_band,
       COUNT(*)                    AS billionaire_count,
       ROUND(SUM(net_worth_bn), 2) AS total_wealth_bn,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM billionaires), 2) AS pct_of_people
FROM banded
GROUP BY wealth_band
ORDER BY wealth_band;

-- Q18. The five oldest billionaires (completes the age picture started in Q2).
SELECT rank, name, age, country, industry, net_worth_bn
FROM billionaires
ORDER BY age DESC, net_worth_bn DESC
LIMIT 5;

-- Q19. United States vs the rest of the world: headcount, wealth and average fortune.
SELECT CASE WHEN country = 'United States' THEN 'United States' ELSE 'Rest of world (34 countries)' END AS region,
       COUNT(*)                    AS billionaire_count,
       ROUND(SUM(net_worth_bn), 2) AS total_wealth_bn,
       ROUND(AVG(net_worth_bn), 2) AS avg_net_worth_bn,
       ROUND(AVG(age), 1)          AS avg_age
FROM billionaires
GROUP BY CASE WHEN country = 'United States' THEN 'United States' ELSE 'Rest of world (34 countries)' END
ORDER BY total_wealth_bn DESC;
