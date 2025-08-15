-- Here are some Italy COVID-19 data questions from a data analytics bootcamp, along with my answers below.

-- Combine the regional and national tables. Show both regional and national total confirmed cases, and rename columns as needed.
SELECT
  DATE(DR.date) AS date
  , DR.region_code
  , DR.region_name
  , DR.total_confirmed_cases AS regional_total_cases
  , NT.total_confirmed_cases AS national_total_cases
FROM 
  `bigquery-public-data.covid19_italy.data_by_region` DR
LEFT JOIN
  `bigquery-public-data.covid19_italy.national_trends` NT
  ON DATE(DR.date) = DATE(NT.date);


-- How much did region 5 contribute in total testing? (i.e. total regional testing / total national testing)? Show on a daily basis for August 2020.
SELECT
  DATE(DR.date) AS date
  , DR.region_code
  , DR.region_name
  , DR.tests_performed AS regional_total_testing
  , NT.tests_performed AS national_total_testing
  , (DR.tests_performed/NT.tests_performed) AS pct_contribution
FROM
  `bigquery-public-data.covid19_italy.data_by_region` DR
LEFT JOIN
  `bigquery-public-data.covid19_italy.national_trends` NT
  ON DATE(DR.date) = DATE(NT.date)
WHERE
  (DR.region_code = '5')
  AND (DATE(DR.date) BETWEEN '2020-08-01' AND '2020-08-31');


-- Show region 3’s contribution to total national cases, as of August 01, 2021.
SELECT
  DATE(DR.date) AS date
  , DR.region_code
  , DR.region_name
  , DR.total_confirmed_cases AS regional_total_cases
  , NT.total_confirmed_cases AS national_total_cases
  , (DR.total_confirmed_cases/NT.total_confirmed_cases) AS pct_contribution
FROM
  `bigquery-public-data.covid19_italy.data_by_region` DR
LEFT JOIN
  `bigquery-public-data.covid19_italy.national_trends` NT
  ON DATE(DR.date) = DATE(NT.date)
WHERE
  (DR.region_code = '3')
  AND (DATE(DR.date) = '2021-08-01');


-- Which region had the highest contribution in total current national cases, as of October 31, 2021?
SELECT
  DATE(DR.date) AS date
  , DR.region_code
  , DR.region_name
  , DR.total_current_confirmed_cases AS regional_current_cases
  , NT.total_current_confirmed_cases AS national_current_cases
  , (DR.total_current_confirmed_cases/NT.total_current_confirmed_cases) AS pct_contribution
FROM
  `bigquery-public-data.covid19_italy.data_by_region` DR
LEFT JOIN
  `bigquery-public-data.covid19_italy.national_trends` NT
  ON DATE(DR.date) = DATE(NT.date)
WHERE
  DATE(DR.date) = '2021-10-31'
ORDER BY
  6 DESC;


-- Show the contribution of each province to the total regional cases, for each day. Only include days where total regional confirmed cases > 0.
SELECT
  DATE(DP.date) AS date
  , DP.region_code
  , DP.name AS region_name
  , DR.total_confirmed_cases AS regional_cases
  , DP.province_code
  , DP.province_name
  , DP.confirmed_cases AS provincial_cases
  , (DP.confirmed_cases/DR.total_confirmed_cases) AS pct_contribution
FROM
  `bigquery-public-data.covid19_italy.data_by_province` DP
LEFT JOIN
  `bigquery-public-data.covid19_italy.data_by_region` DR
  ON DATE(DP.date) = DATE(DR.date) AND DP.region_code = DR.region_code
WHERE
  DR.total_confirmed_cases > 0;


-- Which province had the highest contribution to total national cases, for November 01, 2021?
SELECT
  DATE(DP.date) AS date
  , NT.total_confirmed_cases AS national_cases
  , DP.province_code
  , DP.province_name
  , DP.confirmed_cases AS provincial_cases
  , (DP.confirmed_cases/NT.total_confirmed_cases) AS pct_contribution
FROM
  `bigquery-public-data.covid19_italy.data_by_province` DP
LEFT JOIN
  `bigquery-public-data.covid19_italy.national_trends` NT
  ON DATE(DP.date) = DATE(NT.date)
WHERE
  DATE(DP.date) = '2021-11-01'
ORDER BY
  6 DESC
LIMIT
  1;


-- For October 10,2021, show the contribution of each province to regional and national total cases. Exclude any instances where there is no match in region.
SELECT
  DATE(DP.date) AS date
  , DP.region_code
  , DP.name AS region_name
  , DR.total_confirmed_cases AS regional_cases
  , DP.province_code
  , DP.province_name
  , DP.confirmed_cases AS provincial_cases
  , (DP.confirmed_cases/DR.total_confirmed_cases) AS regional_pct_contribution
  , (DP.confirmed_cases/NT.total_confirmed_cases) AS national_pct_contribution
FROM
  `bigquery-public-data.covid19_italy.data_by_province` DP
INNER JOIN
  `bigquery-public-data.covid19_italy.data_by_region` DR
  ON DATE(DP.date) = DATE(DR.date) AND DP.region_code = DR.region_code
INNER JOIN
  `bigquery-public-data.covid19_italy.national_trends` NT
  ON DATE(DP.date) = DATE(NT.date)
WHERE
  DATE(DP.date) = '2021-10-10';


-- Show the daily new current confirmed cases per region, and its corresponding level (0-500 = low, 501 – 1000 = Medium, >1000 = High; else negative). Consider only August 2021 to October 2021
SELECT
  DATE(DR.date) AS date
  , DR.region_code
  , DR.region_name
  , DR.new_current_confirmed_cases
  , CASE
      WHEN DR.new_current_confirmed_cases BETWEEN 0 AND 500 THEN 'Low'
      WHEN DR.new_current_confirmed_cases BETWEEN 501 AND 1000 THEN 'Medium'
      WHEN DR.new_current_confirmed_cases > 1000 THEN 'High'
    ELSE 'Negative'
  END AS level
FROM
  `bigquery-public-data.covid19_italy.data_by_region` DR
WHERE
  DATE(DR.date) BETWEEN'2021-08-01' AND '2021-10-31';


-- What is the average positivity rate (total confirmed/tests performed) for each region and level (as defined in the previous question), per month? Consider only August 2021 to October 2021.
WITH avg_rates AS (
  SELECT
    DATE_TRUNC(DATE(DR.date), MONTH) AS month
    , DR.region_code AS region_code
    , DR.region_name AS region_name
    , AVG(DR.total_confirmed_cases/DR.tests_performed) AS avg_positivity_rate
  FROM
    `bigquery-public-data.covid19_italy.data_by_region` DR
  WHERE
    DATE(DR.date) BETWEEN'2021-08-01' AND '2021-10-31'
  GROUP BY
    1, 2, 3
)

SELECT
  AR.month
  , AR.region_code
  , AR.region_name
  , AR.avg_positivity_rate
  , CASE
      WHEN AR.avg_positivity_rate < 0.05 THEN 'Low'
      WHEN AR.avg_positivity_rate >= 0.05 AND AR.avg_positivity_rate < 0.10 THEN 'Medium'
      WHEN AR.avg_positivity_rate >= 0.10 THEN 'High'
  END AS level
FROM
  avg_rates AR;


-- Get the national positivity rate and hospitalization rate (current hospitalized/current cases) as of the most recent date available.
SELECT
  DATE(NT.date) AS date
  , (NT.total_confirmed_cases/NT.tests_performed) AS positivity_rate
  , (NT.total_hospitalized_patients/NT.total_current_confirmed_cases) AS hospitalization_rate
FROM `bigquery-public-data.covid19_italy.national_trends` NT
WHERE
  DATE(NT.date) =
  (SELECT MAX(DATE(NT.date))
    FROM `bigquery-public-data.covid19_italy.national_trends` NT);


-- Compare the daily sum of new current cases of all regions to the national totals, using a subquery.
WITH national AS (
  SELECT
    DATE(NT.date) AS date
    , SUM(NT.new_current_confirmed_cases) AS national_new_current_cases
  FROM
    `bigquery-public-data.covid19_italy.national_trends` NT
  GROUP BY
    1
)

SELECT
  DATE(DR.date) AS date
  , SN.national_new_current_cases
  , SUM(DR.new_current_confirmed_cases) AS regional_new_current_cases
  , (SN.national_new_current_cases-(SUM(DR.new_current_confirmed_cases))) AS difference
FROM
  `bigquery-public-data.covid19_italy.data_by_region` DR
INNER JOIN
  national SN
  ON DATE(DR.date) = DATE(SN.date)
GROUP BY
  1, 2;


-- What percentage of the total historical case increase did the increases from October 2020 to December 2020 make up (i.e. sum of October 2020 to December 2020 increase/sum of all increase). Show for each region.
WITH specific_increase AS (
      SELECT
        DR.region_code
        , DR.region_name
        , SUM(DR.new_total_confirmed_cases) AS fourth_qtr_increase
      FROM `bigquery-public-data.covid19_italy.data_by_region` DR
      WHERE DATE(DR.date) BETWEEN '2020-10-01' AND '2020-12-31'
      GROUP BY 1, 2
)

SELECT
  DR.region_code
  , DR.region_name
  , SI.fourth_qtr_increase
  , SUM(DR.new_total_confirmed_cases) AS overall_increase
  , (SI.fourth_qtr_increase/SUM(DR.new_total_confirmed_cases)) AS pct_increase
FROM
  `bigquery-public-data.covid19_italy.data_by_region` DR
INNER JOIN
  specific_increase SI
  ON SI.region_code = DR.region_code
GROUP BY
  1, 2, 3;


-- Let Sector 1 = regions 1,2,3,4; Sector 2 = regions 5,6,7,8,9,10, Sector 3 = regions 11,12,13, Sector 4 = all other regions. Show each sector’s average increase in cases per month, from Jan 2021 to Oct 2021 
SELECT
  DATE_TRUNC(DATE(DR.date), MONTH) AS month
  , CASE
      WHEN DR.region_code IN ('1','2','3','4') THEN 'Sector 1'
      WHEN DR.region_code IN ('5','6','7','8','9','10') THEN 'Sector 2'
      WHEN DR.region_code IN ('11','12','13') THEN 'Sector 3'
      ELSE 'Sector 4'
    END AS sector_code
  , AVG(DR.new_total_confirmed_cases) AS avg_total_increase
FROM
  `bigquery-public-data.covid19_italy.data_by_region` DR
WHERE
  DATE_TRUNC(DATE(DR.date), MONTH) BETWEEN '2021-01-01' AND '2021-10-01'
GROUP BY
  1, 2;


-- How many unique days are there in total in the national trends table?
SELECT
  COUNT(DISTINCT(DATE(NT.date))) AS unique_date_count
FROM
  `bigquery-public-data.covid19_italy.national_trends` NT;


-- Which weeks had more than 100,000 in new total cases, nationally?  Order by earliest week first.
SELECT
  DATE_TRUNC((DATE(NT.date)), WEEK) AS week
  , SUM(NT.new_total_confirmed_cases) as new_total_cases
FROM
  `bigquery-public-data.covid19_italy.national_trends` NT
GROUP BY
  1
HAVING
  SUM(NT.new_total_confirmed_cases) > 100000
ORDER BY
  1;


-- Which region has the most number of distinct provinces?
SELECT
  DP.region_code
  , DP.name AS region_name
  , COUNT(DISTINCT(DP.province_code)) AS unique_province_count
FROM
  `bigquery-public-data.covid19_italy.data_by_province` DP
GROUP BY
  1, 2
ORDER BY
  3 DESC;


-- Show the average hospitalization rate (total hospitalized/total current confirmed cases), per month per region. Include in the average only the days where the new current confirmed cases is more than 2000.
SELECT
  DATE_TRUNC(DATE(DR.date), MONTH) AS month
  , DR.region_code
  , DR.region_name
  , AVG(DR.total_hospitalized_patients/DR.total_current_confirmed_cases) AS avg_hospitalization_rate
FROM
  `bigquery-public-data.covid19_italy.data_by_region` DR
WHERE
  DR.new_current_confirmed_cases > 2000
GROUP BY
  1, 2, 3;


-- Show the average death rate per week for regions 1,5,6,8, and 11. Consider only Oct 03 – Oct 30 2021
SELECT
  DATE_TRUNC((DATE(DR.date)), WEEK) AS week
  , DR.region_code
  , DR.region_name
  , AVG(DR.deaths/DR.total_confirmed_cases) AS avg_death_rate
FROM
  `bigquery-public-data.covid19_italy.data_by_region` DR
WHERE
  (DR.region_code IN ('1','5','6','8','11'))
  AND (DATE_TRUNC((DATE(DR.date)), WEEK) BETWEEN '2021-10-03' AND '2021-10-30')
GROUP BY
  1, 2, 3;


-- On a national level, which day in the first quarter of 2021 registered the highest ratio of home confinement cases to total current cases?
SELECT
  DATE(NT.date) AS date
  , NT.home_confinement_cases
  , NT.total_current_confirmed_cases
  , (NT.home_confinement_cases/NT.total_current_confirmed_cases) AS confinement_current_cases_ratio
FROM
  `bigquery-public-data.covid19_italy.national_trends` NT
WHERE
  DATE(NT.date) BETWEEN '2021-01-01' AND '2021-03-31'
ORDER BY
  4 DESC
LIMIT
  1;


-- Consider these sectors: 
-- Sector 1: regions 1,5,7,19
-- Sector 2: regions 2,6,8,11
-- Sector 3: regions 3,4,12,13,14
-- Sector 4: regions 9,15,16
-- Sector 5: all other regions 
-- Show the average recovery rate (recovered/total cases) per month per sector
SELECT
  DATE_TRUNC(DATE(DR.date), MONTH) AS month
  , CASE
      WHEN DR.region_code IN ('1','5','7','19') THEN 'Sector 1'
      WHEN DR.region_code IN ('2','6','8','11') THEN 'Sector 2'
      WHEN DR.region_code IN ('3','4','12','13','14') THEN 'Sector 3'
      WHEN DR.region_code IN ('9','15','16') THEN 'Sector 4'
      ELSE 'Sector 5'
    END AS sector
  , AVG(DR.recovered/DR.total_confirmed_cases) AS total_cases
FROM
  `bigquery-public-data.covid19_italy.data_by_region` DR
WHERE DR.total_confirmed_cases > 0
GROUP BY
  1, 2;